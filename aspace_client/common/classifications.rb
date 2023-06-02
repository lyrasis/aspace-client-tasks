module Common
  class Classifications < Thor
    desc 'get_classifications', 'retrieve API response of all classification data in ASpace'
    def get_classifications
      page = 1
      data = []
      response = Aspace_Client.client.get('classifications', query: {page: page})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('classifications', query: {page: page})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_classifications_all_ids', 'retrieve API response of all classifications ids. returns an array of integers'
    def get_classifications_all_ids
      Aspace_Client.client.use_global_repository
      response = Aspace_Client.client.get('classifications', query: {all_ids: true})
      response.result
    end

    desc 'make_index', 'create the following index - "title:uri"'
    def make_index
      data = execute 'common:classifications:get_classifications'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc "attach_classifications DATA, FIELDS", "attach classifications refs to object by matching values from the given fields. assumes DATA is an array of hashes, FIELD is a string"
    long_desc <<-LONGDESC
      This method assumes that the field values are contained in an array. 

      @param data [Array<Hash>] the data to which to attach classification URIs 
      @param fields [String or Array] name of the fields that contain the values with which to attach classification URIs
      @return [Array<Hash>] data with classification URIs attached
    LONGDESC
    def attach_classifications(data, fields)
      index = execute "common:classifications:make_index"
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        classifications_refs = record["classifications__refs"].nil? ? [] : record["classifications__refs"]
        [fields].each do |field|
          record[field].each { |entity| classifications_refs << index[entity] }
        end
        record["classifications__refs"] = classifications_refs
      end

      data
    end

    desc 'post_classifications DATA, TEMPLATE', 'given data and template filename (no extension), ingest classifications via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to post 
      @param template [String] the name of the template file without file extension
      @return [nil] sends data to API. If there's an error, instead sends error to log file
    LONGDESC
    def post_classifications(data, template)
      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('classifications', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_classifications_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'delete_classifications', 'delete all classifications via API'
    def delete_classifications
      Aspace_Client.client.use_global_repository
      # shape: [1,2,3]
      data = execute 'common:classifications:get_classifications_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("classifications/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
