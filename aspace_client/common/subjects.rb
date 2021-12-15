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
      data = invoke 'aspace_client:subjects:get_subjects'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post_subjects PATH, FILE', 'given a data file and template, ingest subjects via the ASpace API'
    def post_subjects(path,file)
      Aspace_Client.client.use_global_repository
      data = JSON.parse(File.read(File.join(path,file)))
      data = JSON.parse(data)
      data.each do |row|
        json = ArchivesSpace::Template.process(:subjects, row)
        response = Aspace_Client.client.post('subjects', json)
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end