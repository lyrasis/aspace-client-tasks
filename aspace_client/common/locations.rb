module Common
  class Locations < Thor
    desc 'get_locations', 'retrieve API response of all location data in ASpace'
    def get_locations
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('locations', query: {page: page, page_size: 250})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('locations', query: {page: page, page_size: 250})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_locations_all_ids', 'retrieve API response of all location ids. returns an array of integers'
    def get_locations_all_ids
      response = Aspace_Client.client.get('locations', query: {all_ids: true})
      data = response.result
    end

    desc 'make_index FIELD', 'create the following index for locations - FIELD:uri. This is commonly used to embed location URIs in other record types'
    long_desc <<-LONGDESC
      @param field [String] name of the field that contains the unique values with which to create the hash keys
      @return [Hash] where the key is the unique field value and the value is the URI
    LONGDESC
    def make_index(field)
      puts "making location index"
      data = execute 'common:locations:get_locations'
      index = {}
      data.each do |record|
        index[record[field]] = record['uri']
      end
      index
    end

    desc 'attach_locations DATA FIELD', 'attach locations refs to object by matching values from the given field'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to which to attach location URIs
      @param field [String] name of the field that contains the unique values with which to create the hash keys
      @return [Array<Hash>] DATA with embedded location URIs
    LONGDESC
    def attach_locations(data,field)
      puts "attaching location URIs"
      index = execute "common:locations:make_index", [field]
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        locations_refs = record["locations__refs"].nil? ? [] : record["locations__refs"]
        locations_refs << index[record[field]]
        record["locations__refs"] = locations_refs
      end

      data
    end

    desc 'post_locations DATA TEMPLATE', 'given data and template filename (no extension), ingest locations via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to send to ASpace
      @param template [String] the name of the ERB template (without extension) to use
      @return [nil] posts data to ASpace
    LONGDESC
    def post_locations(data,template)
      Aspace_Client.client.use_global_repository

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('locations', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_locations_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'delete_locations', 'delete all locations via API'
    def delete_locations
      # shape: [1,2,3]
      data = execute 'common:locations:get_locations_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("locations/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end

  end
end
