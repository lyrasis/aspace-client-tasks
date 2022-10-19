# insert your project name or whatever you want to call your local grouping
module Project_Name
  class Objects < Thor

    desc 'attach_resources PATH, FILE', 'attach resource ref to object'
    def attach_resources(path,file)
      index = invoke 'common:objects:make_index_resources'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        resource_ref = nil
        unless record['resource_id'].nil?
          resource_ref = {'ref' => index[record['resource_id']]}
        end
        record['resource__ref'] = resource_ref
      end
      
      data
    end

    desc 'attach_resource_parent_ids PATH, RESOURCE_FILE, AO_FILE', 'attach resource identifiers from output file to archival object output file'
    def attach_resource_parent_ids(path,resource_file,ao_file)
      # open data files
      resource_data = JSON.parse(File.read(File.join(path,resource_file)))
      ao_data = JSON.parse(File.read(File.join(path,ao_file)))
      # create index used to insert resource identifiers into archival object dataset
      resource_ids = []
      resource_data.each do |record|
        # index[record['resource_id']] = record['id_0']
        resource_ids << record['id_0']
      end
      # insert resource identifiers using index
      ao_data.each do |record|
        if resource_ids.include? record['link']
          record['resource_id'] = record['link']
        else
          record['resource_id'] = nil
        end
      end
      
      data
    end

    # outdated, but serves as an example of how you might write a method that combines entity attachments
    desc 'attach_all_entities PATH, FILE', 'attach all entity refs to object'
    def attach_all_entities(path, file)
      classifications_index = invoke 'common:classifications:make_index'
      subjects_index = invoke 'common:subjects:make_index'
      people_index = invoke 'common:agents:make_index_people'
      corporate_index = invoke 'common:agents:make_index_corporate'
      families_index = invoke 'common:agents:make_index_families'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        # classifications
        classification_refs = []
        record['classifications'].each do |classification|
          classification_refs << classifications_index[classification]
        end
        record['classification__refs'] = classification_refs
        # subjects
        subject_refs = []
        record['subject__terms'].each do |subject|
          subject_refs << subjects_index[subject]
        end
        record['subject__refs'] = subject_refs
        # people
        creator_person_refs = []
        linked_agents_refs = []
        record['creator_person'].each do |person|
          creator_person_refs << {'ref' => people_index[person], 'role' => record['creator_person_role']}
        end
        record['linked_agents__subject'].each do |linked_agent|
          linked_agents_refs << {'ref' => people_index[linked_agent], 'role' => record['linked_agents__subject__role']}
        end
        record['creator_person__refs'] = creator_person_refs
        record['linked_agents__refs'] = linked_agents_refs
        # corporate
        creator_corporate_ref = nil
        unless record['creator_corporate'].nil?
          creator_corporate_ref = {'ref' => corporate_index[record['creator_corporate']], 'role' => record['creator_corporate_role']}
        end
        record['creator_corporate__ref'] = creator_corporate_ref
        # families
        creator_family_ref = nil
        unless record['creator_family'].nil?
          creator_family_ref = {'ref' => families_index[record['creator_family']], 'role' => record['creator_family_role']}
        end
        record['creator_family__ref'] = creator_family_ref
      end

      data
    end

    # in theory this works but is untested. Notes data file was too large to load
    # see update_resources_with_notes for alternative approach
    desc 'attach_notes_resources PATH, FILE', 'attach notes to resources using identifier'
    def attach_notes_resources(path,file,*args)
      puts "loading notes..."
      note_data = JSON.parse(File.read(File.join(path,file)))
      puts "notes loaded. getting resources..."
      resource_data = invoke 'common:objects:get_resources'
      # loop through each resource record and attach notes based on unique identifier
      puts "resources retrieved. attaching notes..."
      resource_data.each do |record|
        # notes = note_data.select {|noteset| noteset['objectid'] == record['id_0']}
        notes = note_data.lazy.select {|noteset| noteset['objectid'] == record['id_0']}.first(1)
        # create structure hash using the notes_resource erb template
        # using the ArchivesSpace Client to create nested JSON from an ERB template
        json = ArchivesSpace::Template.process(:notes_resource, notes[0])
        # then need to turn it back into a hash to put into an array
        record['notes'] = JSON.parse(json)
      end
      puts "notes attached"
      
      resource_data
    end

    # in theory this works but is untested. Notes data file was too large to load
    # see update_aos_with_notes for alternative approach
    desc 'attach_notes_aos PATH, FILE', 'attach notes to archival objects using identifier'
    def attach_notes_resources(path,file,*args)
      note_data = JSON.parse(File.read(File.join(path,file)))
      ao_data = invoke 'common:objects:get_aos'
      # loop through each archival object record and attach notes based on unique identifier
      ao_data.each do |record|
        # notes = note_data.select {|noteset| noteset['objectid'] == record['component_id']}
        notes = note_data.lazy.select {|noteset| noteset['objectid'] == record['component_id']}.first(1)
        # create structure hash using the notes_ao erb template
        # using the ArchivesSpace Client to create nested JSON from an ERB template
        json = ArchivesSpace::Template.process(:notes_ao, notes[0])
        # then need to turn it back into a hash to put into an array
        record['notes'] = JSON.parse(json)
      end
      
      ao_data
    end

    desc 'make_index_links PATH, FILE', 'create the following index - "component_id:parent_id,resource_id"'
    def make_index_links(path,file,*args)
      data = JSON.parse(File.read(File.join(path,file)))
      index = {}
      data.each do |record|
        index[record['component_id']] = {'parent_id' => record['link'], 'resource_id' => record['resource_id']}
      end
      index
    end

    desc 'attach_resource_id_to_children', 'attach resource_id to child aos by searching parent aos'
    def attach_resource_id_to_children(path,file)
      data = JSON.parse(File.read(File.join(path,file)))
      log_path = Aspace_Client.log_path
      index = invoke 'make_index_links',[path,file], []
      puts data[0]
      problem_ids = []
      data.each do |record|
        current_id = record['component_id']
        while record['resource_id'] == nil
          puts "current_id: #{current_id}"
          puts index[current_id]
          if index[current_id] == nil
            problem_ids << current_id
            record['resource_id'] = "%EXCLUDE%"
          elsif index[current_id]['resource_id'] != nil
            record['resource_id'] = index[current_id]['resource_id']
          else
            current_id = index[current_id]['parent_id']
          end
        end
      end
      # remove any records with problem ids
      data_exclude_problem_ids = data.reject {|record| record['resource_id'] == "%EXCLUDE%"}
      
      # create log of problem ids
      File.open(File.join(log_path,"problem_ids.txt"),"w") do |f|
        f.write(problem_ids)
      end

      data_exclude_problem_ids
    end

    desc 'update_resources_with_notes PATH, FILE', 'given dataset, update resources via the ASpace API by matching on index'
    def update_resources_with_notes(path,file)
      puts "making index..."
      index = execute 'aspace_client:objects:make_index_resources',[],[]
      puts "index complete. getting resources..."
      resource_data = execute 'aspace_client:objects:get_resources',[],[]
      log_path = Aspace_Client.log_path
      error_log = []
      # loop through index
      puts "updating resources..."
      io = StringIO.new File.read(File.join(path,file), :encoding => "UTF-8") # here a file stream is opened
      # building JSON objects byte by byte
      loop.inject(counter: 0, string: '') do |acc|
        char = io.getc

        break if char.nil? # EOF
        next acc if acc[:counter].zero? && char != '{' # between objects

        acc[:string] << char
        if char == '}' && (acc[:counter] -= 1).zero?
          # ⇓⇓⇓ # CALLBACK, feel free to JSON.parse here
          # puts acc[:string].gsub(/\p{Space}+/, ' ') 
          note_record = JSON.parse(acc[:string].gsub(/\p{Space}+/, ' '))
          # attaching notes to resource
          resource_record = resource_data.lazy.select {|record| record['id_0'] == note_record['objectid']}.first(1)
          unless resource_record.empty?
            resource_record = resource_record[0]
            json = ArchivesSpace::Template.process(:notes_resource, note_record)
            resource_record['notes'] = JSON.parse(json)
            # have to pull out "archival_objects/number" since we're setting base repo
            ref_split = index[resource_record['id_0']].split('/')
            response = Aspace_Client.client.post("#{ref_split[3]}/#{ref_split[4]}",resource_record.to_json)
            puts response.result.success? ? "=)" : ["id_0: #{resource_record['id_0']}", "resource_ref: #{index[resource_record['id_0']]}",response.result.to_json]
            # adding error if error is present
            error_log << ["id_0: #{resource_record['id_0']}", "resource_ref: #{index[resource_record['id_0']]}",response.result.to_json] if response.result.success? == false
          end

          # start building next record
          next {counter: 0, string: ''} # from scratch
        end

        acc.tap do |result|
          result[:counter] += 1 if char == '{'
        end
      end

      puts "resources updated. writing error log"
      # write any errors to error log and save to file
      write_path = File.join(log_path,"update_resources_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

    desc 'update_aos_with_notes PATH, FILE', 'given dataset, update archival objects via the ASpace API by matching on index'
    def update_aos_with_notes(path,file)
      puts "making index..."
      index = execute 'aspace_client:objects:make_index_aos',[],[]
      puts "index complete. getting archival objects..."
      ao_data = execute 'aspace_client:objects:get_aos',[],[]
      log_path = Aspace_Client.log_path
      error_log = []
      # loop through index
      puts "updating archival objects..."
      io = StringIO.new File.read(File.join(path,file), :encoding => "UTF-8") # here a file stream is opened
      # building JSON objects byte by byte
      loop.inject(counter: 0, string: '') do |acc|
        char = io.getc

        break if char.nil? # EOF
        next acc if acc[:counter].zero? && char != '{' # between objects

        acc[:string] << char
        if char == '}' && (acc[:counter] -= 1).zero?
          # ⇓⇓⇓ # CALLBACK, feel free to JSON.parse here
          # puts acc[:string].gsub(/\p{Space}+/, ' ') 
          note_record = JSON.parse(acc[:string].gsub(/\p{Space}+/, ' '))
          # attaching notes to resource
          ao_record = ao_data.lazy.select {|record| record['component_id'] == note_record['objectid']}.first(1)
          unless ao_record.empty?
            ao_record = ao_record[0]
            json = ArchivesSpace::Template.process(:notes_ao, note_record)
            ao_record['notes'] = JSON.parse(json)
            # have to pull out "archival_objects/number" since we're setting base repo
            ref_split = index[ao_record['component_id']].split('/')
            response = Aspace_Client.client.post("#{ref_split[3]}/#{ref_split[4]}",ao_record.to_json)
            puts response.result.success? ? "=)" : ["id_0: #{ao_record['component_id']}", "resource_ref: #{index[ao_record['component_id']]}",response.result.to_json]
            # adding error if error is present
            error_log << ["id_0: #{ao_record['component_id']}", "resource_ref: #{index[ao_record['component_id']]}",response.result.to_json] if response.result.success? == false
          end

          # start building next record
          next {counter: 0, string: ''} # from scratch
        end

        acc.tap do |result|
          result[:counter] += 1 if char == '{'
        end
      end

      puts "archival objects updated. writing error log"
      # write any errors to error log and save to file
      write_path = File.join(log_path,"update_aos_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

    desc 'move_aos_children PATH, FILE', 'build hierarchy of existing archival objects by matching id:uri index to data file'
    def move_aos_children(path,file)
      # set up data
      index = invoke 'common:objects:make_index_aos'
      data = JSON.parse(File.read(File.join(path,file)))
      
      # set up error log
      log_path = Aspace_Client.log_path
      error_log = []
      
      # approach 1. loads a single child of a parent - starts with data
      data.each do |record|
        unless record['link'].nil?
          component_ref = index[record['component_id']]
          parent_ref = index[record['link']]
          unless parent_ref.nil?
            parent_ref = parent_ref.split("/")
            parent_ref = "#{parent_ref[-2]}/#{parent_ref[-1]}"
            response = Aspace_Client.client.post("#{parent_ref}/accept_children", "",{position: 1, children: [component_ref]})
            puts response.result.success? ? '=)' : response.result
            error_log << ["component ref: #{component_ref}","parent ref: #{parent_ref}",response.result.to_json] if response.result.success? == false
          end
        end
      end

      # write any errors to error log and save to file
      write_path = File.join(log_path,"move_aos_children_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'post_aos_children PATH, FILE', 'post new archival objects as children of existing archival objects by matching id:uri index to data file'
    def post_aos_children(path,file)
      # set up data
      index = invoke 'common:objects:make_index_aos'
      data = JSON.parse(File.read(File.join(path,file)))
      
      # set up error log
      log_path = Aspace_Client.log_path
      error_log = []

      # load all children of a given parent - starts with index
      index.each do |parent_component_id, parent_ref|
        children_group = {"jsonmodel_type"=>"archival_record_children","children"=>[]}
        children = data.select {|record| record['link'] == parent_component_id}
        children.each do |child|
          # using the ArchivesSpace Client to create nested JSON from an ERB template
          json = ArchivesSpace::Template.process(:aos, child)
          # then need to turn it back into a hash to put into an array
          children_group['children'] << JSON.parse(json)
        end

        response = Aspace_Client.client.post("#{parent_ref}/children", children_group.to_json)
        # puts response.result.success? ? '=)' : response.result
        puts response.result.success? ? '=)' : ["component refs: #{children_group}","parent ref: #{parent_ref}",response.result.to_json]
        error_log << ["component refs: #{children_group}","parent ref: #{parent_ref}",response.result.to_json] if response.result.success? == false

        error_log << response.result if response.result.success? == false
      end

      # write any errors to error log and save to file
      write_path = File.join(log_path,"post_aos_children_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    # could do this one in kiba-extend before outing to json
    # actually, couldn't do this one in kiba-extend because we have to attach resource-ids before running this
    desc 'select_aos_with_resource_id PATH, FILE', 'select archival objects that have resource ids'
    def select_aos_with_resource_id(path,file)
      # load data from file
      data = JSON.parse(File.read(File.join(path,file)))
      with_ids = data.reject {|record| record['resource_id'].nil?}
      
      with_ids
    end

    # could do this one in kiba-extend before outing to json
    # actually, couldn't do this one in kiba-extend because we have to attach resource-ids before running this
    desc 'select_aos_without_resource_id PATH, FILE', 'select archival objects that don\'t have resource ids'
    def select_aos_without_resource_id(path,file)
      # load data from file
      data = JSON.parse(File.read(File.join(path,file)))
      missing_ids = data.select {|record| record['resource_id'].nil?}
      
      missing_ids
    end

    # could do this one in kiba-extend before outing to json
    desc 'select_aos_with_link PATH, FILE', 'select archival objects that have a link'
    def select_aos_with_link(path,file)
      # load data from file
      data = JSON.parse(File.read(File.join(path,file)))
      with_links = data.reject {|record| record['link'].nil?}
      
      with_links
    end

    # could do this one in kiba-extend before outing to json
    desc 'select_aos_without_link PATH, FILE', 'select archival objects that don\'t have a link'
    def select_aos_without_link(path,file)
      # load data from file
      data = JSON.parse(File.read(File.join(path,file)))
      # refactored to be less verbose
      missing_links = data.select {|record| record['link'].nil?}
      
      missing_links
    end

  end
end
