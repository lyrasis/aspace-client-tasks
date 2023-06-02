module Common
  class ContainerProfiles < Thor
    desc 'get_container_profiles', 'retrieve API response of all container profile data in ASpace'
    def get_container_profiles
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('container_profiles', query: {page: page})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('container_profiles', query: {page: page})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_container_profiles_all_ids', 'retrieve API response of all container profie ids. returns an array of integers'
    def get_container_profiles_all_ids
      Aspace_Client.client.use_global_repository
      response = Aspace_Client.client.get('container_profiles', query: {all_ids: true})
      response.result
    end

    desc 'make_index FIELD', 'create the following index for container profiles - FIELD:uri. This is commonly used to embed container profile URIs in other record types'
    long_desc <<-LONGDESC
      @param field [String] name of the field in the API data that contains the unique values with which to create the hash keys
      @return [Hash] where the key is the unique field value and the value is the URI
    LONGDESC
    def make_index(field)
      puts "making container profile index"
      data = execute 'common:container_profiles:get_container_profiles'
      index = {}
      data.each do |record|
        index[record[field]] = record['uri']
      end
      index
    end

    desc 'attach_container_profiles DATA, API_FIELD, SOURCE_FIELD', 'attach container profiles refs to object by matching values from the given fields'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to which to attach container profile URIs
      @param api_field [String] name of the field in the API data that contains the unique values to match upon
      @param source_field [String] names of the field in the source data that contains the values to match upon
      @return [Array<Hash>] data with embedded container profile URIs
    LONGDESC
    def attach_container_profiles(data, api_field, source_field)
      index = execute "common:container_profiles:make_index", [api_field]
      puts "attaching container profile URIs"
      data.each do |record|
        record["container_profile__ref"] = index[record[source_field]] unless record[source_field].nil?
      end

      data
    end

    desc 'post_container_profiles DATA, TEMPLATE', 'given data and template filename (no extension), ingest container_profiles via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to send to ASpace
      @param template [String] the name of the template (without extension) to use
      @return [nil] posts data to ASpace
    LONGDESC
    def post_container_profiles(data, template)
      Aspace_Client.client.use_global_repository

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('container_profiles', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_container_profiles_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'delete_container_profiles', 'delete all container profiles via API'
    def delete_container_profiles
      Aspace_Client.client.use_global_repository
      # shape: [1,2,3]
      data = execute 'common:container_profiles:get_container_profiles_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("container_profiles/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
