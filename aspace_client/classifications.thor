require_relative '../aspace_client'
require 'json'
require 'pry'

module Aspace_Client
  class Classifications < Thor
    desc 'get classifications', 'retrieve API response of all classification data in ASpace'
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

    desc 'make index', 'create the following index - "title:uri"'
    def make_index(*args)
      data = invoke 'aspace_client:classifications:get_classifications'
      index = {}
      data.each do |record|
        index[record['title']] = record['uri']
      end
      index
    end

    desc 'post classifications', 'given a data file and template, ingest classifications via the ASpace API'
    def post_classifications

      path = File.join(Aspace_Client.datadir, 'classifications_out.json')
      data = File.read(path)
      data = JSON.parse(data)
      data.each do |row|
        json = ArchivesSpace::Template.process(:classifications, row)
        response = Aspace_Client.client.post('classifications', json)
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
