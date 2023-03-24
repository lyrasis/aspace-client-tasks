module Common
  class TopContainers < Thor
    desc 'get_top_containers', 'retrieve API response of all top container data in ASpace'
    def get_top_containers
      page = 1
      data = []
      response = Aspace_Client.client.get('top_containers', query: {page: page, page_size: 250})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('top_containers', query: {page: page, page_size: 250})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_top_containers_all_ids', 'retrieve API response of all top container ids. returns an array of integers'
    def get_top_containers_all_ids
      response = Aspace_Client.client.get('top_containers', query: {all_ids: true})
      data = response.result
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

    desc 'attach_top_containers DATA FIELD', 'attach top container ref to object by matching values from the given field'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to which to attach top_container URIs
      @param field [String] name of the field that contains the unique values with which to create the hash keys
      @return [Array<Hash>] DATA with embedded top_container URIs
    LONGDESC
    def attach_top_containers(data,field)
      puts "attaching top container URIs"
      index = execute "common:top_containers:make_index", [field]
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        # top_container_ref = record["top_containers__refs"].nil? ? [] : record["top_containers__refs"]
        # record[field].each {|entity| top_containers_refs << index[entity]}
        record["top_container__ref"] = index[record[field]] unless record[field].nil?
      end

      data
    end

    desc 'post_top_containers DATA TEMPLATE', 'given data and template filename (no extension), ingest top_containers via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to send to ASpace
      @param template [String] the name of the ERB template (without extension) to use
      @return [nil] posts data to ASpace
    LONGDESC
    def post_top_containers(data,template)
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
