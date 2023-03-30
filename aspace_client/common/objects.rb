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

    desc 'get_children_of_ao REF', 'retrieve all children archival object records of the referenced object'
    long_desc <<~LONGDESC
    @param ref [String] The API URI ref of the record whose children records to retrieve.
    @param return [Array<Hash>] An array of hash records for each child.
    LONGDESC
    def get_children_of_ao(ref)
      response = Aspace_Client.client.get("#{ref.split("/")[3]}/#{ref.split("/")[4]}/children")
      data = response.result
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
      end
      index
    end

    desc "attach_resources DATA, FIELD", "attach resource ref to object by matching values from the given field"
    long_desc <<-LONGDESC
      @param data [Array<Hash>] The data to attach resource refs to.
      @param field [String] The field in data to use to match resource refs to associated records.
      @return [Array<Hash>] Returns data with resource refs added.
    LONGDESC
    def attach_resources(data,field)
      index = execute "common:objects:make_index_resources"
      data.each do |record|
        record["resource__ref"] = index[record[field]]
      end

      data
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

    desc 'move_aos_children_to_parents, DATA SOURCE_ID PARENT_ID COMPONENT_ID_OR_EXTERNAL_ID', 'move archival objects to their parent archival objects'
    long_desc <<-LONGDESC
    @param data [Array<Hash>] The data to reference when moving archival objects.
    @param source_id [String] The field in `data` on which to match the record to its API counterpart record.
    @param parent_id [String] The field in `data` on which to match the record to its API parent record.
    @param component_id_or_external_id [String] The field in the ASpace data on which to match.
      Options for this param are: component_id or external_id. external_id picks the first external_id in the record.
    @return [nil] Moves the archival object to the specificed parent. If there's an error, it will be printed to the terminal and written
      to an error log.
    LONGDESC
    def move_aos_children_to_parents(data,source_id,parent_id,component_id_or_external_id)
      # ensures component_id_or_external_id is one of the expected string values. raise an error otherwise
      raise ArgumentError.new "expecting component_id_or_external_id to be one of two values: component_id or external_id" unless %w[component_id external_id].include? component_id_or_external_id

      puts "making index..."
      index = execute 'common:objects:make_index_aos_dynamic', [component_id_or_external_id]
      puts "getting archival objects..."
      api_data = execute 'common:objects:get_aos'
      log_path = Aspace_Client.log_path
      error_log = []

      ids_to_limit = []

      # collect all the record ids so we don't have to run through every API record
      data.each do |record|
        ids_to_limit << record[source_id]
      end

      # conditionally grab the record ID for the given record
      api_record_id = ->(api_record,component_id_or_external_id) {
        case component_id_or_external_id
        when 'component_id'
          return api_record['component_id']
        when 'external_id'
          return api_record['external_ids'][0]['external_id']
        end
      }

      # filter API records whose ID is in the list of source data IDs
      api_data.select!{|api_record| ids_to_limit.include? api_record_id.call(api_record,component_id_or_external_id)}

      # wrapper for posting API record under its parent API record
      poster = ->(record) {
        unless record['parent'] == nil || record['parent']['ref'] == nil
          ref_split = record['parent']['ref'].split('/')
          response = Aspace_Client.client.post("#{ref_split[3]}/#{ref_split[4]}/accept_children", "",{position: 1, children: [record['uri']]})
          puts response.result.success? ? "=)" : response.result
          error_log << response.result if response.result.success? == false
        end
      }

      api_data.each do |api_record|
        matching_data = data.lazy.select {|record| record[source_id] == api_record_id.call(api_record,component_id_or_external_id)}.first(1)[0]

        if matching_data == nil
          error_log << "no matching ID for record #{api_record['uri']}"
        else
          # pull the URI of the parent API record and append to current API record
          api_record['parent'] = {"ref" => index[matching_data[parent_id]]}
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

    desc 'post_aos_children DATA TEMPLATE PARENT_ID COMPONENT_ID_OR_EXTERNAL_ID', 'post new archival objects as children of existing archival objects by matching id:uri index to data file'
    long_desc <<-LONGDESC
    This task assumes that the referenced parent is already in ASpace. An example use-case for using this task is if you have many thousand item-level records
      that you want to post as children of hierarchical records that are already in ASpace.\n\n
    @param data [Array<Hash>] The data to reference when moving archival objects.
    @param template [String] The name (without extension) of the template file to use to process the records.
    @param parent_id [String] The field in `data` on which to match the record to its API parent record.
    @param component_id_or_external_id [String] The field in the ASpace data on which to match.
      Options for this param are: component_id or external_id. external_id picks the first external_id in the record.
      @return [nil] Posts the archival object to the referenced parent. If there's an error, it will be printed to the terminal and written
      to an error log.
    LONGDESC
    def post_aos_children(data,template,parent_id,component_id_or_external_id)
      # ensures component_id_or_external_id is one of the expected string values. raise an error otherwise
      raise ArgumentError.new "expecting component_id_or_external_id to be one of two values: component_id or external_id" unless %w[component_id external_id].include? component_id_or_external_id

      puts "making index..."
      index = execute 'common:objects:make_index_aos_dynamic', [component_id_or_external_id]
      log_path = Aspace_Client.log_path
      error_log = []
      parent_ids_to_limit = []

      # collect all the record ids so we don't have to run through every API record
      data.each do |record|
        parent_ids_to_limit << record[parent_id] unless parent_ids_to_limit.include? record[parent_id]
      end

      # filtering only the index keys that are for parent records
      index.select!{|key,value| parent_ids_to_limit.include? key}

      # wrapper for posting children to parent via API
      poster = ->(parent_ref,children_group) {
        unless children_group['children'].empty?
          response = Aspace_Client.client.post("#{parent_ref.split("/")[3]}/#{parent_ref.split("/")[4]}/children", children_group.to_json)
          puts response.result.success? ? "=)" : response.result
          error_log << {"parent ref"=> parent_ref,"child_refs" => children_group,"response" => response.result} if response.result.success? == false

        end
      }

      process_children = ->(parent_id_index,data,template,parent_id) {
        children_group = {"jsonmodel_type"=>"archival_record_children","children"=>[]}
        children = data.select {|record| record[parent_id] == parent_id_index[0]}
        children.each do |child|
          # using the ArchivesSpace Client to create nested JSON from an ERB template
          json = ArchivesSpace::Template.process(template.to_sym, child)
          # then need to turn it back into a hash to put into an array
          children_group['children'] << JSON.parse(json)
          poster.call(parent_id_index[1],children_group)
          # puts children_group
          children_group['children'] = []
        end
        children = nil

        puts "Children processed for #{parent_id_index[1]}. #{index.count - 1} parents to go"
      }

      # instead of looping through the item-level records, we want to loop through the parent record ids
      # then gather all the item-level records whose parent id matches the parent record id
      # then run them through the template, re-hash them, then send the group through the poster
      while index.count > 0
        process_children.call(index.first,data,template,parent_id)

        index.shift

      end

      write_path = File.join(log_path,"post_children_aos_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

    desc 'post_aos_children_intermediary_grouping DATA TEMPLATE PARENT_ID COMPONENT_ID_OR_EXTERNAL_ID', 'post new archival objects as children of an arbitrary grouping existing archival objects by matching id:uri index to data file'
    long_desc <<-LONGDESC
    This task first associates the records with their ASpace parents. Then, it creates intermediary groupings and posts records to these groupings. This task
      assumes that the referenced parent is already in ASpace. This is meant for resources that have very long and flat levels. For example, a resource with 
      25,000 archival objects at a single level. It assumes you want groupings of 1,000 and that you want the grouping names to be 'Group X', where X is an 
      incrementing number.\n\n
    @param data [Array<Hash>] The data to reference when moving archival objects.
    @param template [String] The name (without extension) of the template file to use to process the records.
    @param parent_id [String] The field in `data` on which to match the record to its API parent record.
    @param component_id_or_external_id [String] The field in the ASpace data on which to match.
      Options for this param are: component_id or external_id. external_id picks the first external_id in the record.
    @return [nil] Posts the archival object an intermediary grouping under the referenced parent. If there's an error, it will be printed to the terminal and written
      to an error log.
    LONGDESC
    def post_aos_children_intermediary_grouping(data,template,parent_id,component_id_or_external_id)
      # ensures component_id_or_external_id is one of the expected string values. raise an error otherwise
      raise ArgumentError.new "expecting component_id_or_external_id to be one of two values: component_id or external_id" unless %w[component_id external_id].include? component_id_or_external_id

      puts "making index..."
      index = execute 'common:objects:make_index_aos_dynamic', [component_id_or_external_id]
      log_path = Aspace_Client.log_path
      error_log = []
      parent_ids_to_limit = []

      # collect all the record ids so we don't have to run through every API record
      data.each do |record|
        parent_ids_to_limit << record[parent_id] unless parent_ids_to_limit.include? record[parent_id]
      end

      # filtering only the index keys that are for parent records
      index.select!{|key,value| parent_ids_to_limit.include? key}

      # wrapper for posting children to parent via API
      poster = ->(parent_ref,children_group) {
        unless children_group['children'].empty?
          response = Aspace_Client.client.post("#{parent_ref.split("/")[3]}/#{parent_ref.split("/")[4]}/children", children_group.to_json)
          puts response.result.success? ? "=)" : response.result
          error_log << {"parent ref"=> parent_ref,"child_refs" => children_group,"response" => response.result} if response.result.success? == false
          return response
        end
      }

      # ingests imtermediary records and then ingests objects to those parents
      process_children = ->(parent_id_index,data,template,parent_id) {
        children_record = {"jsonmodel_type"=>"archival_record_children","children"=>[]}
        children = data.select {|record| record[parent_id] == parent_id_index[0]}

        # creates all the intermediary parent records - one per 1,000 children
        i = 1
        (children.length / 1000 + 1).times do |create|
          record = {"title"=>"Group #{i}", "level"=>"subseries", "resource"=>{"ref"=>children.first['resource__ref']}}
          children_record['children'] << record
          poster.call(parent_id_index[1],children_record)
          children_record['children'] = []
          i += 1
        end

        # get all the intermediary parent record ref ids. array of strings.
        intermediary_parents = execute 'common:objects:get_children_of_ao', [parent_id_index[1]]
        intermediary_parent_refs = intermediary_parents.map{|record| record['uri']}

        # post 1,000 children to the first intermediary_parent
        # when it hits 1,000, move to the next intermediary_parent and reset number to 0
        # repeat
        i = 0
        children.each do |child|
          if i == 1000
            intermediary_parent_refs.shift
            i = 0
          end
          # using the ArchivesSpace Client to create nested JSON from an ERB template
          json = ArchivesSpace::Template.process(template.to_sym, child)
          # then need to turn it back into a hash to put into an array
          children_record['children'] << JSON.parse(json)

          poster.call(intermediary_parent_refs.first,children_record)

          children_record['children'] = []
          i += 1
        end
        children = nil

        puts "Children processed for #{parent_id_index[1]}. #{index.count - 1} parents to go"
      }

      # instead of looping through the item-level records, we want to loop through the parent record ids
      # then gather all the item-level records whose parent id matches the parent record id
      # then run them through the template, re-hash them, then send the group through the poster
      while index.count > 0
        process_children.call(index.first,data,template,parent_id)

        index.shift

      end

      write_path = File.join(log_path,"post_children_aos_intermediary_grouping_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

  end
end
