module Common
  class Classifications < Thor
    desc 'get_classifications', 'retrieve API response of all classification data in ASpace'
    def get_classifications(*args)
      page = 1
      data = []
      response = Aspace_Client.client.get('classifications', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('classifications', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'make_index', 'create the following index - "title:uri"'
    def make_index(*args)
      data = invoke 'get_classifications'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc "attach_classifications", "attach classifications refs to object by matching values from the given field. assumes DATA is an array of hashes, FIELD is a string"
    def attach_classifications(data,field)
      index = invoke "common:classifications:make_index"
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        classifications_refs = record["classifications__refs"].nil? ? [] : record["classifications__refs"]
        record[field].each {|entity| classifications_refs << index[entity]}
        record["classifications__refs"] = classifications_refs
      end

      data
    end

    desc 'post_classifications DATA, TEMPLATE', 'given data and template filename (no extension), ingest classifications via the ASpace API'
    def post_classifications(data,template)

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

  end
end

