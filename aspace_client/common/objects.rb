module Common
  class Objects < Thor
    no_commands do 
      def execute(task, args, options)
        (klass, task) = Thor::Util.find_class_and_command_by_namespace(task)
        klass.new.invoke(task, args, options)
      end
    end

    desc 'attach_classifications PATH, FILE, FIELD', 'attach classification refs to object by matching values from the given field. assumes FIELD is an array'
    def attach_classifications(path,file,field)
      index = invoke 'common:classifications:make_index'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        classification_refs = []
        record[field].each do |classification|
          classification_refs << index[classification]
        end
        record['classification__refs'] = classification_refs
      end
      
      data
    end

    desc 'attach_subjects PATH, FILE, FIELD', 'attach subject refs to object by matching values from the given field. assumes FIELD is an array'
    def attach_subjects(path,file,field)
      index = invoke 'common:subjects:make_index'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        subject_refs = []
        record[field].each do |subject|
          subject_refs << index[subject]
        end
        record['subject__refs'] = subject_refs
      end
      
      data
    end

    desc 'attach_linked_people PATH, FILE, FIELD, ROLE', 'attach linked people refs to object by matching values from the given field. assume FIELD is an array and ROLE is a string'
    def attach_linked_people(path,file,field,role)
      index = invoke 'common:agents:make_index_people'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        linked_people_refs = []
        record[field].each do |person|
          linked_people_refs << {'ref' => index[person], 'role' => role}
        end
        record['linked_people__refs'] = linked_people_refs
      end
      
      data
    end

    desc 'attach_linked_corporate PATH, FILE, FIELD, ROLE', 'attach linked corporate refs to object by matching values from the given field. assume FIELD is an array and ROLE is a string'
    def attach_linked_corporate(path,file,field,role)
      index = invoke 'common:agents:make_index_corporate'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        linked_corporate_refs = []
        record[field].each do |corporate|
          linked_corporate_refs << {'ref' => index[corporate], 'role' => role}
        end
        record['linked_corporate__refs'] = linked_corporate_refs
      end
      
      data
    end

    desc 'attach_linked_families PATH, FILE, FIELD, ROLE', 'attach linked family refs to object by matching values from the given field. assume FIELD is an array and ROLE is a string'
    def attach_linked_families(path,file,field,role)
      index = invoke 'common:agents:make_index_families'
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |record|
        linked_families_refs = []
        record[field].each do |family|
          linked_families_refs << {'ref' => index[family], 'role' => role}
        end
        record['linked_families__refs'] = linked_families_refs
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

    desc 'post_resources PATH, FILE, TEMPLATE', 'given a data file and template filename (no extension), ingest resources via the ASpace API'
    def post_resources(path,file,template)
      data = JSON.parse(File.read(File.join(path,file)))
      log_path = Aspace_Client.log_path
      error_log = []
      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('resources', json)
        puts response.result.success? ? '=)' : response.result
        error_log << response.result if response.result.success? == false
      end

      File.open(File.join(log_path,"post_resources_error_log.txt"), "w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

    desc 'post_aos PATH, FILE, TEMPLATE', 'given a data file and template filename (no extension), ingest archival objects via the ASpace API'
    def post_aos(path,file,template)
      # setting up the data
      data = JSON.parse(File.read(File.join(path,file)))

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []
      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
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
