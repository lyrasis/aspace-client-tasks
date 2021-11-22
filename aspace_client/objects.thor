require_relative '../aspace_client'
require 'json'
require 'csv'
require 'pry'
require 'stringio'

module Aspace_Client
  class Objects < Thor
    # include Aspace_Client
    # binding.pry
    # Aspace_Client.client.config.base_repo = "repositories/101"
    no_commands do 
      def execute(task, args, options)
        (klass, task) = Thor::Util.find_class_and_command_by_namespace(task)
        klass.new.invoke(task, args, options)
      end
    end


    desc 'attach_classifications', 'attach classification refs to object'
    options :path => :string, :file => :string
    def attach_classifications
      index = invoke 'aspace_client:classifications:make_index'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      data.each do |record|
        classification_refs = []
        record['classifications'].each do |classification|
          classification_refs << index[classification]
        end
        record['classification__refs'] = classification_refs
      end
      write_path = File.join(path, "#{options[:file][0..-6]}_classifications.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'attach_subjects', 'attach subject refs to object'
    options :path => :string, :file => :string
    def attach_subjects
      index = invoke 'aspace_client:subjects:make_index'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      data.each do |record|
        subject_refs = []
        record['subject__terms'].each do |subject|
          subject_refs << index[subject]
        end
        record['subject__refs'] = subject_refs
      end
      write_path = File.join(path, "#{options[:file][0..-6]}_subjects.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'attach_people', 'attach people refs to object'
    options :path => :string, :file => :string
    def attach_people
      index = invoke 'aspace_client:agents:make_index_people'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      data.each do |record|
        creator_person_ref = nil
        linked_agents_refs = []
        unless record['creator_person'].nil?
          creator_person_ref = {'ref' => index[record['creator_person']], 'role' => record['creator_person_role']}
        end
        record['linked_agents__subject'].each do |linked_agent|
          linked_agents_refs << {'ref' => index[linked_agent], 'role' => record['linked_agents__subject__role']}
        end
        record['creator_person__ref'] = creator_person_ref
        record['linked_agents__refs'] = linked_agents_refs
      end
      write_path = File.join(path, "#{options[:file][0..-6]}_people.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'attach_corporate', 'attach corporate refs to object'
    options :path => :string, :file => :string
    def attach_corporate
      index = invoke 'aspace_client:agents:make_index_corporate'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      data.each do |record|
        creator_corporate_ref = nil
        unless record['creator_corporate'].nil?
          creator_corporate_ref = {'ref' => index[record['creator_corporate']], 'role' => record['creator_corporate_role']}
        end
        record['creator_corporate__ref'] = creator_corporate_ref
      end
      write_path = File.join(path, "#{options[:file][0..-6]}_corporate.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'attach_family', 'attach family ref to object'
    options :path => :string, :file => :string
    def attach_family
      index = invoke 'aspace_client:agents:make_index_families'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      data.each do |record|
        creator_family_ref = nil
        unless record['creator_family'].nil?
          creator_family_ref = {'ref' => index[record['creator_family']], 'role' => record['creator_family_role']}
        end
        record['creator_family__ref'] = creator_family_ref
      end
      write_path = File.join(path, "#{options[:file][0..-6]}_families.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'attach_resources', 'attach resource ref to object'
    options :path => :string, :file => :string
    def attach_resources
      index = invoke 'aspace_client:objects:make_index_resources'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      data.each do |record|
        resource_ref = nil
        unless record['resource_id'].nil?
          resource_ref = {'ref' => index[record['resource_id']]}
        end
        record['resource__ref'] = resource_ref
      end
      write_path = File.join(path, "#{options[:file][0..-6]}_resources.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'attach_resource_parent_ids', 'attach resource identifiers from output file to archival object output file'
    options :path => :string, :resource_file => :string, :ao_file => :string, :outfile => :string
    def attach_resource_parent_ids
      # open data files
      path = File.expand_path(options[:path])
      resource_data = JSON.parse(File.read(File.join(path,options[:resource_file])))
      ao_data = JSON.parse(File.read(File.join(path,options[:ao_file])))
      # create index used to insert resource identifiers into archival object dataset
      resource_ids = []
      resource_data.each do |record|
        # index[record['resource_id']] = record['id_0']
        resource_ids << record['id_0']
      end
      # insert resource identifiers using index
      ao_data.each do |record|
        # record['resource_id'] = index[record['collection']]
        # # bonus: also add the resource identifier to "link" if "link" is empty
        # record['link'] = index[record['collection']] if record['link'].nil?
        if resource_ids.include? record['link']
          record['resource_id'] = record['link']
        else
          record['resource_id'] = nil
        end
      end
        # write updated data to file
      File.open(File.join(path, options[:outfile]),"w") do |f|
        f.write(ao_data.to_json)
      end
    end

    desc 'attach_all_entities', 'attach all entity refs to object'
    options :path => :string, :file => :string
    def attach_all_entities
      classifications_index = invoke 'aspace_client:classifications:make_index'
      subjects_index = invoke 'aspace_client:subjects:make_index'
      people_index = invoke 'aspace_client:agents:make_index_people'
      corporate_index = invoke 'aspace_client:agents:make_index_corporate'
      families_index = invoke 'aspace_client:agents:make_index_families'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
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
        # unless record['creator_person'].nil?
        #   creator_person_ref = {'ref' => people_index[record['creator_person']], 'role' => record['creator_person_role']}
        # end
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
      write_path = File.join(path, "#{options[:file][0..-6]}_allentities.json")
      File.open(write_path,"w") do |f|
        f.write(data.to_json)
      end
    end

    # in theory this works but is untested. Notes data file was too large to load
    # see update_resources_with_notes for alternative approach
    desc 'attach_notes_resources', 'attach notes to resources using identifier'
    options :file => :string
    def attach_notes_resources(*args)
      path = File.expand_path(Aspace_Client.datadir)
      puts "loading notes..."
      note_data = JSON.parse(File.read(File.join(path,options[:file])))
      puts "notes loaded. getting resources..."
      resource_data = invoke 'aspace_client:objects:get_resources'
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
      return resource_data
    end

    # in theory this works but is untested. Notes data file was too large to load
    # see update_aos_with_notes for alternative approach
    desc 'attach_notes_aos', 'attach notes to archival objects using identifier'
    options :file => :string
    def attach_notes_resources(*args)
      path = File.expand_path(Aspace_Client.datadir)
      note_data = JSON.parse(File.read(File.join(path,options[:file])))
      ao_data = invoke 'aspace_client:objects:get_aos'
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
      return ao_data
    end

    desc 'get_resources', 'retrieve API response of all resource data in ASpace'
    def get_resources(*args)
      Aspace_Client.client.config.base_repo = "repositories/2"
      page = 1
      data = []
      response = Aspace_Client.client.get('resources', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('resources', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_aos', 'retrieve API response of all resource data in ASpace'
    def get_aos(*args)
      Aspace_Client.client.config.base_repo = "repositories/2"
      page = 1
      data = []
      response = Aspace_Client.client.get('archival_objects', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('archival_objects', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_aos_all_ids', 'retrieve API response of all archival object ids. returns an array of integers'
    def get_aos_all_ids(*args)
      Aspace_Client.client.config.base_repo = "repositories/2"
      response = Aspace_Client.client.get('archival_objects', query: {all_ids: true})
      data = response.result
    end

    desc 'make_index_resources', 'create the following index - "id_0:uri"'
    def make_index_resources(*args)
      data = invoke 'aspace_client:objects:get_resources'
      index = {}
      data.each do |record|
        index[record['id_0']] = record['uri']
      end
      index
    end

    desc 'make_index_aos', 'create the following index - "component_id:uri"'
    def make_index_aos(*args)
      data = invoke 'aspace_client:objects:get_aos'
      index = {}
      data.each do |record|
        index[record['component_id']] = record['uri']
      end
      index
    end

    desc 'make_index_links', 'create the following index - "component_id:parent_id,resource_id"'
    options :file => :string
    def make_index_links(*args)
      path = Aspace_Client.datadir
      file = options[:file]
      data = JSON.parse(File.read(File.join(path,file)))
      index = {}
      data.each do |record|
        index[record['component_id']] = {'parent_id' => record['link'], 'resource_id' => record['resource_id']}
      end
      index
    end

    desc 'attach_resource_id_to_children', 'attach resource_id to child aos by searching parent aos'
    options :file => :string
    def attach_resource_id_to_children
      path = Aspace_Client.datadir
      file = options[:file]
      data = JSON.parse(File.read(File.join(path,file)))
      index = invoke 'aspace_client:objects:make_index_links',[], :file => "ao_out_resource_ids_allentities_with_links.json"
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
      # write data to out file
      File.open(File.join(path,"#{file[0..-6]}_allids.json"),"w") do |f|
        f.write(data_exclude_problem_ids.to_json)
      end
      # create log of problem ids
      File.open(File.join(path,"#{file[0..-6]}_problem_ids.txt"),"w") do |f|
        f.write(problem_ids)
      end
    end

    desc 'save_index_aos', 'create and save the following index - "component_id:uri"'
    def save_index_aos
      index = invoke 'aspace_client:objects:make_index_aos'
      # index = {}
      # data.each do |record|
      #   index[record['title']] = record['uri']
      # end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/aos_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'save_resources', 'save API response of all resource data in ASpace'
    def save_resources
      data = invoke 'aspace_client:objects:get_resources'
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/resources.json')
      File.open(path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'save_index_resources', 'create and save the following index - "id_0:uri"'
    def save_index_resources
      index = invoke 'aspace_client:objects:make_index_resources'
      # index = {}
      # data.each do |record|
      #   index[record['title']] = record['uri']
      # end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/resources_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'save_index_links', 'create and save the following index - "component_id:parent_id,resource_id"'
    def save_index_links
      index = invoke 'aspace_client:objects:make_index_links',[], :file => "ao_out_resource_ids.json"
      path = Aspace_Client.datadir
      file = "links_index.json"
      File.open(File.join(path,file),"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'post_resources', 'given a data file and template, ingest resources via the ASpace API'
    def post_resources
      Aspace_Client.client.config.base_repo = "repositories/2"
      path = File.join(Aspace_Client.datadir, 'resources_out_allentities.json')
      data = File.read(path)
      data = JSON.parse(data)
      # binding.pry
      data.each do |row|
        json = ArchivesSpace::Template.process(:resources, row)
        response = Aspace_Client.client.post('resources', json)
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'update_resources_with_notes', 'given dataset, update resources via the ASpace API by matching on index'
    def update_resources_with_notes
      Aspace_Client.client.config.base_repo = "repositories/2"
      puts "making index..."
      index = execute 'aspace_client:objects:make_index_resources',[],[]
      puts "index complete. getting resources..."
      resource_data = execute 'aspace_client:objects:get_resources',[],[]
      log_path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/api_logs")
      error_log = []
      # loop through index
      puts "updating resources..."
      io = StringIO.new File.read("/Users/jshelby/Documents/migrations/aspace/asu-migration/data/aspace/notes_out.json", :encoding => "UTF-8") # here a file stream is opened
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

    desc 'post_aos', 'given a data file and template, ingest archival objects via the ASpace API'
    def post_aos
      Aspace_Client.client.config.base_repo = "repositories/2"
      # setting up the data
      path = File.join(Aspace_Client.datadir, 'ao_out_resource_ids_allentities_with_links_allids_resources.json')
      data = File.read(path)
      data = JSON.parse(data)

      # setting up error log
      log_path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/api_logs")
      error_log = []
      # binding.pry
      data.each do |row|
        json = ArchivesSpace::Template.process(:aos, row)
        response = Aspace_Client.client.post('archival_objects', json)
        puts response.result.success? ? '=)' : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_aos_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'update_aos_with_notes', 'given dataset, update archival objects via the ASpace API by matching on index'
    def update_aos_with_notes
      Aspace_Client.client.config.base_repo = "repositories/2"
      puts "making index..."
      index = execute 'aspace_client:objects:make_index_aos',[],[]
      puts "index complete. getting archival objects..."
      ao_data = execute 'aspace_client:objects:get_aos',[],[]
      log_path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/api_logs")
      error_log = []
      # loop through index
      puts "updating archival objects..."
      io = StringIO.new File.read("/Users/jshelby/Documents/migrations/aspace/asu-migration/data/aspace/notes_out.json", :encoding => "UTF-8") # here a file stream is opened
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

    desc 'move_aos_children', 'build hierarchy of existing archival objects by matching id:uri index to data file'
    options :path => :string, :file => :string
    def move_aos_children
      Aspace_Client.client.config.base_repo = "repositories/2"
      # set up data
      index = invoke 'aspace_client:objects:make_index_aos'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      
      # set up error log
      log_path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/api_logs")
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
    #   write_path = File.join(log_path,"move_aos_children_error_log.txt")
    #   File.open(write_path,"w") do |f|
    #   f.write(error_log.join(",\n"))
    #   end
    # end

      # # approach 2. loads all children of a given parent - starts with index
      # index.each do |parent_component_id, parent_ref|
      #   children = data.select {|record| record['link'] == parent_component_id}
      #   children_refs = children.map {|record| index[record['component_id']]}
      #   response = Aspace_Client.client.post("#{parent_ref}/accept_children", { query: { children: children_refs.join(",")}, position: 1})
      #   puts response.result.success? ? '=)' : response.result
      #   error_log << response.result if response.result.success? == false
      # end
      
      # write any errors to error log and save to file
      write_path = File.join(log_path,"move_aos_children_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'post_aos_children', 'pst new archival objects as children of existing archival objects by matching id:uri index to data file'
    options :path => :string, :file => :string
    def post_aos_children
      # if the above comment out works, then will need to remove this and add repositories/2 to the post line
      # Aspace_Client.client.config.base_repo = "repositories/2"
      # set up data
      index = invoke 'aspace_client:objects:make_index_aos'
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      
      # set up error log
      log_path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/api_logs")
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

    desc 'delete_aos', 'delete all archival objects via API'
    def delete_aos
      Aspace_Client.client.config.base_repo = "repositories/2"
      # shape: [1,2,3]
      data = invoke 'aspace_client:objects:get_aos_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("archival_objects/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'find_aos_without_resource_id', 'find archival objects that don\'t have resource ids'
    options :path => :string, :infile => :string, :outfile => :string
    def find_aos_without_resource_id
      # load data from file
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:infile])))
      missing_ids = []
      # loop through data to find records that don't have a resource_id
      data.each do |record|
        missing_ids << record if record['resource_id'].nil?
      end
      # write the filtered data to a new file
      write_path = File.join(path, options[:outfile])
      File.open(write_path,"w") do |f|
        f.write(missing_ids.to_json)
      end
    end

    desc 'find_aos_without_link', 'find archival objects that don\'t have a link'
    options :path => :string, :infile => :string, :outfile => :string
    def find_aos_without_link
      # load data from file
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:infile])))
      # refactored to be less verbose
      missing_links = data.select {|record| record['link'].nil?}
      # missing_links = []
      # # loop through data to find records that don't have a resource_id
      # data.each do |record|
      #   missing_links << record if record['link'].nil?
      # end
      # write the filtered data to a new file
      write_path = File.join(path, options[:outfile])
      File.open(write_path,"w") do |f|
        f.write(missing_links.to_json)
      end
    end

    desc 'split_aos_no_resource_ids', 'splits out archival objects that don\'t have a resource_id'
    options :path => :string, :file => :string
    def split_aos_no_resource_ids
      # load data from file
      path = File.expand_path(options[:path])
      data = JSON.parse(File.read(File.join(path,options[:file])))
      # removes any archival objects that do not have a link so that we can get the show on the road
      data.reject! {|record| record['link'].nil?}
      # create array of records that have a collection
      aos_with_resource_id = data.select {|record| record['resource_id'] != nil}
      # create array of records that do not have a collection
      aos_without_resource_id = data.select {|record| record['resource_id'].nil?}
      # write file with collection
      File.open(File.join(path, "#{options[:file][0..-6]}_with_resource_id.json"),"w") do |f|
        f.write(aos_with_resource_id.to_json)
      end
      # write file without collection
      File.open(File.join(path, "#{options[:file][0..-6]}_without_resource_id.json"),"w") do |f|
        f.write(aos_without_resource_id.to_json)
      end
    end

    desc 'split_aos_no_links', 'splits out archival objects that don\'t have a resource_id'
    options :file => :string
    def split_aos_no_links
      # load data from file
      path = Aspace_Client.datadir
      data = JSON.parse(File.read(File.join(path,options[:file])))
      # create array of records that have a link
      aos_with_link = data.select {|record| record['link'] != nil}
      # create array of records that do not have a link
      aos_without_link = data.select {|record| record['link'].nil?}
      # write file with link
      File.open(File.join(path, "#{options[:file][0..-6]}_with_links.json"),"w") do |f|
        f.write(aos_with_link.to_json)
      end
      # write file without collection
      File.open(File.join(path, "#{options[:file][0..-6]}_without_links.json"),"w") do |f|
        f.write(aos_without_link.to_json)
      end
    end

  end
end
