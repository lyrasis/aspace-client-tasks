module Common
  class Objects < Thor
    no_commands do 
      def execute(task, args, options)
        (klass, task) = Thor::Util.find_class_and_command_by_namespace(task)
        klass.new.invoke(task, args, options)
      end
    end

    desc 'attach_classifications PATH, FILE', 'attach classification refs to object'
    # TODO: potentially refactor to include a parameter to specify the name of the record field containing classification text
    # would need to assume input is an array
    def attach_classifications(path,file)
      index = invoke 'common:classifications:make_index'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        classification_refs = []
        record['classifications'].each do |classification|
          classification_refs << index[classification]
        end
        record['classification__refs'] = classification_refs
      end
      
      data
    end

    desc 'attach_subjects PATH, FILE', 'attach subject refs to object'
    # TODO: same as classifications
    def attach_subjects(path,file)
      index = invoke 'common:subjects:make_index'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        subject_refs = []
        record['subject__terms'].each do |subject|
          subject_refs << index[subject]
        end
        record['subject__refs'] = subject_refs
      end
      
      data
    end

    desc 'attach_people PATH, FILE', 'attach people refs to object'
    # TODO: same as classifications
    def attach_people(path,file)
      index = invoke 'common:agents:make_index_people'
      data = JSON.parse(File.read(File.join(path,file)))
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
      
      data
    end

    desc 'attach_corporate PATH, FILE', 'attach corporate refs to object'
    # TODO: same as classifications
    def attach_corporate(path,file)
      index = invoke 'common:agents:make_index_corporate'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        creator_corporate_ref = nil
        unless record['creator_corporate'].nil?
          creator_corporate_ref = {'ref' => index[record['creator_corporate']], 'role' => record['creator_corporate_role']}
        end
        record['creator_corporate__ref'] = creator_corporate_ref
      end
      
      data
    end

    desc 'attach_family PATH, FILE', 'attach family ref to object'
    # TODO: same as classifications
    def attach_family(path,file)
      index = invoke 'common:agents:make_index_families'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        creator_family_ref = nil
        unless record['creator_family'].nil?
          creator_family_ref = {'ref' => index[record['creator_family']], 'role' => record['creator_family_role']}
        end
        record['creator_family__ref'] = creator_family_ref
      end
      
      data
    end

    desc 'get_resources', 'retrieve API response of all resource data in ASpace'
    def get_resources(*args)
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
      response = Aspace_Client.client.get('archival_objects', query: {all_ids: true})
      data = response.result
    end

    desc 'make_index_resources', 'create the following index - "id_0:uri"'
    def make_index_resources(*args)
      data = invoke 'get_resources'
      index = {}
      data.each do |record|
        index[record['id_0']] = record['uri']
      end
      index
    end

    desc 'make_index_aos', 'create the following index - "component_id:uri"'
    def make_index_aos(*args)
      data = invoke 'get_aos'
      index = {}
      data.each do |record|
        index[record['component_id']] = record['uri']
      end
      index
    end

    desc 'post_resources PATH, FILE', 'given a data file and template, ingest resources via the ASpace API'
    def post_resources(path,file)
      data = JSON.parse(File.read(File.join(path,file)))
      log_path = Aspace_Client.log_path
      error_log = []
      data.each do |row|
        json = ArchivesSpace::Template.process(:resources, row)
        response = Aspace_Client.client.post('resources', json)
        puts response.result.success? ? '=)' : response.result
        error_log << response.result if response.result.success? == false
      end

      File.open(File.join(log_path,"post_resources_error_log.txt"), "w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

    desc 'post_aos PATH, FILE', 'given a data file and template, ingest archival objects via the ASpace API'
    def post_aos(path,file)
      # setting up the data
      data = JSON.parse(File.read(File.join(path,file)))

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []
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

    desc 'delete_aos', 'delete all archival objects via API'
    def delete_aos
      # shape: [1,2,3]
      data = invoke 'get_aos_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("archival_objects/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end

  end
end
