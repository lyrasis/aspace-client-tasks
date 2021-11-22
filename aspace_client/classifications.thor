require_relative '../aspace_client'
require 'json'

module Aspace_Client
  class Classifications < Thor
    # include Aspace_Client
    # binding.pry
    # Aspace_Client.client.config.base_repo = "repositories/101"
    desc 'get classifications', 'retrieve API response of all classification data in ASpace'
    def get_classifications(*args)
      page = 1
      data = []
      response = Aspace_Client.client.get('repositories/2/classifications', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('repositories/2/classifications', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'make index', 'create the following index - "title:uri"'
    def make_index(*args)
      data = invoke 'aspace_client:classifications:get_classifications'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'save classifications', 'save API response of all classification data in ASpace'
    def save_classifications
      data = invoke 'aspace_client:classifications:get_classifications'
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/classifications.json')
      File.open(path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'save index', 'create and save the following index - "title:uri"'
    def save_index
      data = invoke 'aspace_client:classifications:get_classifications'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/classifications_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'post classifications', 'given a data file and template, ingest classifications via the ASpace API'
    def post_classifications
      # Aspace_Client.client.config.base_repo = "repositories/101"
      # binding.pry

      Aspace_Client.client.config.base_repo = "repositories/2"
      path = File.join(Aspace_Client.datadir, 'classifications_out.json')
      data = File.read(path)
      data = JSON.parse(data)
      # binding.pry
      data.each do |row|
        json = ArchivesSpace::Template.process(:classifications, row)
        response = Aspace_Client.client.post('classifications', json)
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
