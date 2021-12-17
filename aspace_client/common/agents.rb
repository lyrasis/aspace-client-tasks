module Common
  class Agents < Thor
    desc 'get_people', 'retrieve API response of all personal name data in ASpace'
    def get_people(*args)
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('agents/people', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('agents/people', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'make_index_people', 'create the following index - "title:uri"'
    def make_index_people(*args)
      data = invoke 'get_people'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post_people PATH, FILE, TEMPLATE', 'given a data file and template filename (no extension), ingest personal names via the ASpace API'
    def post_people(path,file,template)
      Aspace_Client.client.use_global_repository
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('agents/people', json)
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'get_corporate', 'retrieve API response of all corporate name data in ASpace'
    def get_corporate(*args)
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('agents/corporate_entities', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('agents/corporate_entities', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'make_index_corporate', 'create the following index - "title:uri"'
    def make_index_corporate(*args)
      data = invoke 'get_corporate'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post_corporate PATH, FILE, TEMPLATE', 'given a data file and template filename (no extension), ingest corporate names via the ASpace API'
    def post_corporate(path,file,template)
      Aspace_Client.client.use_global_repository
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('agents/corporate_entities', json)
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'get_families', 'retrieve API response of all family name data in ASpace'
    def get_families(*args)
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('agents/families', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('agents/families', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'make_index_families', 'create the following index - "title:uri"'
    def make_index_families(*args)
      data = invoke 'get_families'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post_families PATH, FILE, TEMPLATE', 'given a data file and template filename (no extension), ingest family names via the ASpace API'
    def post_families(path,file,template)
      Aspace_Client.client.use_global_repository
      data = JSON.parse(File.read(File.join(path,file)))
      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('agents/families', json)
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'publish_all_agents', 'publish all agents in an ASpace instance, except any agent that has the key "is_user"'
    def publish_all_agents
      people = invoke 'get_people'
      corporate = invoke 'get_corporate'
      families = invoke 'get_families'

      people.each do |person|
        unless person.keys.include? "is_user"
          response = Aspace_Client.client.post("#{person['uri']}/publish",'')
          puts response.result.success? ? '=)' : response.result
        end
      end

      corporate.each do |corporate_entity|
        unless corporate_entity.keys.include? "is_user"
          response = Aspace_Client.client.post("#{corporate_entity['uri']}/publish",'')
          puts response.result.success? ? '=)' : response.result
        end
      end

      families.each do |family|
        unless family.keys.include? "is_user"
          response = Aspace_Client.client.post("#{family['uri']}/publish",'')
          puts response.result.success? ? '=)' : response.result
        end
      end
    end

  end
end
