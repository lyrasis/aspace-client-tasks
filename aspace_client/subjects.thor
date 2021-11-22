require_relative '../aspace_client'
require 'json'

module Aspace_Client
  class Subjects < Thor
    # include Aspace_Client
    # binding.pry
    # Aspace_Client.client.config.base_repo = "repositories/101"
    desc 'get subjects', 'retrieve API response of all subject data in ASpace'
    def get_subjects(*args)
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

    desc 'make index', 'create the following index - "title:uri"'
    def make_index(*args)
      data = invoke 'aspace_client:subjects:get_subjects'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'save subjects', 'save API response of all subject data in ASpace'
    def save_subjects
      data = invoke 'aspace_client:subjects:get_subjects'
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/subjects.json')
      File.open(path,"w") do |f|
        f.write(data.to_json)
      end
    end

    desc 'save index', 'create and save the following index - "title:uri"'
    def save_index
      data = invoke 'aspace_client:subjects:get_subjects'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      path = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/api_testing/subjects_index.json')
      File.open(path,"w") do |f|
        f.write(index.to_json)
      end
    end

    desc 'post subjects', 'given a data file and template, ingest subjects via the ASpace API'
    def post_subjects
      # Aspace_Client.client.config.base_repo = "repositories/101"
      # binding.pry

      # Aspace_Client.client.config.base_repo = "repositories/2"
      path = File.join(Aspace_Client.datadir, 'subjects_out.json')
      data = File.read(path)
      data = JSON.parse(data)
      # binding.pry
      data.each do |row|
        json = ArchivesSpace::Template.process(:subjects, row)
        response = Aspace_Client.client.post('subjects', json)
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
