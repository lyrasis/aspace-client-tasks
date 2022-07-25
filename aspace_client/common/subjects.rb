module Common
  class Subjects < Thor
    desc 'get_subjects', 'retrieve API response of all subject data in ASpace'
    def get_subjects(*args)
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('subjects', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('subjects', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'make_index', 'create the following index - "title:uri"'
    def make_index(*args)
      data = invoke 'get_subjects'
      index = {}
      data.each do |record|
        index[record['title'].gsub(" -- ", "--")] = record['uri']
      end
      index
    end

    desc 'post_subjects DATA, TEMPLATE', 'given data and template filename (no extension), ingest subjects via the ASpace API'
    def post_subjects(data,template)
      Aspace_Client.client.use_global_repository

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('subjects', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_subjects_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

  end
end
