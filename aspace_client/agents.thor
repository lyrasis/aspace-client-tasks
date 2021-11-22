require_relative '../aspace_client'

module Aspace_Client
  class Agents < Thor
    desc 'get people', 'retrieve API response of all personal name data in ASpace'
    def get_people(*args)
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

    desc 'make index for people', 'create the following index - "title:uri"'
    def make_index_people(*args)
      data = invoke 'aspace_client:agents:get_people'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'save people', 'save API response of all people data in ASpace'
    def save_people
      data = invoke 'aspace_client:agents:get_people'
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/people.json')
      File.open(path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'save index for people', 'create and save the following index - "title:uri"'
    def save_index_people
      data = invoke 'aspace_client:agents:get_people'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/people_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'post people', 'given a data file and template, ingest personal names via the ASpace API'
    def post_people
      path = File.join(Aspace_Client.datadir, 'creator_people_out.json')
      data = File.read(path)
      data = JSON.parse(data)
      data.each do |row|
        json = ArchivesSpace::Template.process(:people, row)
        response = Aspace_Client.client.post('agents/people', json)
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'get corporate entities', 'retrieve API response of all corporate name data in ASpace'
    def get_corporate(*args)
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

    desc 'make index for corporate entities', 'create the following index - "title:uri"'
    def make_index_corporate(*args)
      data = invoke 'aspace_client:agents:get_corporate'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'save corporate entities', 'save API response of all corporate entity data in ASpace'
    def save_corporate
      data = invoke 'aspace_client:agents:get_corporate'
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/people.json')
      File.open(path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'save index for corporate entities', 'create and save the following index - "title:uri"'
    def save_index_corporate
      data = invoke 'aspace_client:agents:get_corporate'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/corporate_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'post corporate entities', 'given a data file and template, ingest corporate names via the ASpace API'
    def post_corporate()
      path = File.join(Aspace_Client.datadir, 'creator_corporate_out.json')
      data = File.read(path)
      data = JSON.parse(data)
      data.each do |row|
        json = ArchivesSpace::Template.process(:corporate, row)
        response = Aspace_Client.client.post('agents/corporate_entities', json)
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'get families', 'retrieve API response of all family name data in ASpace'
    def get_families(*args)
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

    desc 'make index for families', 'create the following index - "title:uri"'
    def make_index_families(*args)
      data = invoke 'aspace_client:agents:get_families'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'save families', 'save API response of all family data in ASpace'
    def save_families
      data = invoke 'aspace_client:agents:get_families'
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/families.json')
      File.open(path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'save index for families', 'create and save the following index - "title:uri"'
    def save_index_families
      data = invoke 'aspace_client:agents:get_families'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/families_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'post families', 'given a data file and template, ingest family names via the ASpace API'
    def post_families
      path = File.join(Aspace_Client.datadir, 'creator_families_out.json')
      data = File.read(path)
      data = JSON.parse(data)
      data.each do |row|
        json = ArchivesSpace::Template.process(:families, row)
        response = Aspace_Client.client.post('agents/families', json)
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
