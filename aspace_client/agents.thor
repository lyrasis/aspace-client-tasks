require_relative '../aspace_client'
require 'pry' #dev

module Aspace_Client
  class Agents < Thor
    desc 'get people', 'retrieve API response of all personal name data in ASpace'
    def get_people(*args)
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('agents/people', query: {page: page, page_size: 100})
      binding.pry
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

    desc 'post people', 'given a data file and template, ingest personal names via the ASpace API'
    def post_people
      Aspace_Client.client.use_global_repository
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

    desc 'make index for corporate entities', 'create the following index - "title:uri"'
    def make_index_corporate(*args)
      data = invoke 'aspace_client:agents:get_corporate'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post corporate entities', 'given a data file and template, ingest corporate names via the ASpace API'
    def post_corporate
      Aspace_Client.client.use_global_repository
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

    desc 'make index for families', 'create the following index - "title:uri"'
    def make_index_families(*args)
      data = invoke 'aspace_client:agents:get_families'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post families', 'given a data file and template, ingest family names via the ASpace API'
    def post_families
      Aspace_Client.client.use_global_repository
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
