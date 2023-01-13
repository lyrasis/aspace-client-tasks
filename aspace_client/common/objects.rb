module Common
  class Objects < Thor

    desc 'get_resources', 'retrieve API response of all resource data in ASpace'
    def get_resources
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
    def get_aos
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
    def get_aos_all_ids
      response = Aspace_Client.client.get('archival_objects', query: {all_ids: true})
      data = response.result
    end

    desc 'make_index_resources', 'create the following index - "id_0:uri"'
    def make_index_resources
      data = execute 'common:objects:get_resources'
      index = {}
      data.each do |record|
        index[record['id_0']] = record['uri']
      end
      index
    end

    desc 'make_index_aos', 'create the following index - "component_id:uri"'
    def make_index_aos
      data = execute 'common:objects:get_aos'
      index = {}
      data.each do |record|
        index[record['component_id']] = record['uri']
      end
      index
    end

    desc 'make_index_aos_dynamic COMPONENT_ID_OR_EXTERNAL_ID', 'create the following index - "component_id_or_external_id:uri". options for component_id_or_external_id are: component_id or external_id. external_id picks the first external_id in the record'
    def make_index_aos_dynamic(component_id_or_external_id)
      # ensures component_id_or_external_id is one of the expected string values. raise an error otherwise
      raise ArgumentError.new "expecting component_id_or_external_id to be one of two values: component_id or external_id" unless %w[component_id external_id].include? component_id_or_external_id

      data = execute 'common:objects:get_aos'
      index = {}
      data.each do |record|
        case component_id_or_external_id
        when 'component_id'
          index[record['component_id']] = record['uri']
        when 'external_id'
          index[record['external_ids'][0]['external_id']] = record['uri']
        end
      index
      end
    end

    desc 'post_resources DATA, TEMPLATE', 'given data and template filename (no extension), ingest resources via the ASpace API'
    def post_resources(data,template)
      
      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('resources', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_aos_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'post_aos DATA, TEMPLATE', 'given data and template filename (no extension), ingest archival objects via the ASpace API'
    def post_aos(data,template)

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('archival_objects', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
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
      data = execute 'common:objects:get_aos_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("archival_objects/#{id}")
        puts response.result.success? ? "=) #{data.length - data.find_index(id) - 1} to go" : response.result
      end
    end

    desc 'move_aos_child_to_parent, DATA SOURCE_ID PARENT_ID COMPONENT_ID_OR_EXTERNAL_ID', 'move archival objects to their parent archival objects'
    long_desc <<-LONGDESC
    DATA is an array of hashes; SOURCE_ID is the field in DATA on which to match the record to its API counterpart record; PARENT_ID is the field in DATA 
    on which to match the record to its API parent record; COMPONENT_ID_OR_EXTERNAL_ID is the field in the ASpace data on which to match. options for 
    COMPONENT_ID_OR_EXTERNAL_ID are: component_id or external_id. external_id picks the first external_id in the record
    LONGDESC
    def move_aos_child_to_parent(data,source_id,parent_id,component_id_or_external_id)
      # ensures component_id_or_external_id is one of the expected string values. raise an error otherwise
      raise ArgumentError.new "expecting component_id_or_external_id to be one of two values: component_id or external_id" unless %w[component_id external_id].include? component_id_or_external_id

      puts "making index..."
      index = execute 'common:objects:make_index_aos_dynamic', [component_id_or_external_id]
      puts "getting archival objects..."
      api_data = execute 'common:objects:get_aos'
      log_path = Aspace_Client.log_path
      error_log = []

      # wrapper for posting API record under its parent API record
      poster = ->(record) {
        unless record['parent'] == nil || record['parent']['ref'] == nil
          ref_split = record['uri'].split('/')
          response = Aspace_Client.client.post("#{record['parent']['ref'].split("/")[3]}/#{record['parent']['ref'].split("/")[4]}/accept_children", "",{position: 1, children: [record['uri']]})
          puts response.result.success? ? "=)" : response.result
          error_log << response.result if response.result.success? == false
        end
      }

      api_data.each do |api_record|
        # conditionally grab the record in DATA that matches the current API record
        case component_id_or_external_id
        when 'component_id'
          matching_data = data.lazy.select {|record| record[source_id] == api_record['component_id']}.first(1)
        when 'external_id'
          matching_data = data.lazy.select {|record| record[source_id] == api_record['external_ids'][0]['external_id']}.first(1)
        end

        if matching_data[0] == nil
          error_log << "no matching ID for record #{api_record['uri']}"
        else
          # pull the URI of the parent API record and append to current API record
          api_record['parent'] = {"ref" => index[matching_data[0][parent_id]]}
          # use lambda to post current API record under its parent API record
          poster.call(api_record)
        end

      end
      # write error log
      write_path = File.join(log_path,"move_aos_child_to_parent_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    
    end

  end
end
