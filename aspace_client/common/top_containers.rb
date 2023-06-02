module Common
  class TopContainers < Thor
    desc 'get_top_containers', 'retrieve API response of all top container data in ASpace'
    def get_top_containers
      page = 1
      data = []
      response = Aspace_Client.client.get('top_containers', query: {page: page})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('top_containers', query: {page: page})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_top_containers_all_ids', 'retrieve API response of all top container ids. returns an array of integers'
    def get_top_containers_all_ids
      response = Aspace_Client.client.get('top_containers', query: {all_ids: true})
      response.result
    end

    desc 'make_index FIELD', 'create the following index for top containers - FIELD:uri. This is commonly used to embed top container URIs in other record types'
    long_desc <<-LONGDESC
      @param field [String] name of the field that contains the unique values with which to create the hash keys
      @return [Hash] where the key is the unique field value and the value is the URI
    LONGDESC
    def make_index(field)
      puts "making top container index"
      data = execute 'common:top_containers:get_top_containers'
      index = {}
      data.each do |record|
        index[record[field]] = record['uri']
      end
      index
    end

    desc 'attach_top_containers DATA, API_FIELD, SOURCE_FIELD', 'attach top container ref to object by matching values from the given field'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to which to attach top container URIs
      @param api_field [String] name of the field in the API data that contains the unique values to match upon
      @param source_field [String] name of the field in the source data that contains the values to match upon
      @return [Array<Hash>] data with embedded top container URIs
    LONGDESC
    def attach_top_containers(data, api_field, source_field)
      puts "attaching top container URIs"
      index = execute "common:top_containers:make_index", [api_field]
      data.each do |record|
        record["top_container__ref"] = index[record[source_field]] unless record[source_field].nil?
      end

      data
    end

    desc 'post_top_containers DATA, TEMPLATE', 'given data and template filename (no extension), ingest top_containers via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to send to ASpace
      @param template [String] the name of the ERB template (without extension) to use
      @return [nil] posts data to ASpace
    LONGDESC
    def post_top_containers(data, template)
      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('top_containers', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_top_containers_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'delete_top_containers', 'delete all top containers via API'
    def delete_top_containers
      # shape: [1,2,3]
      data = execute 'common:top_containers:get_top_containers_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("top_containers/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
