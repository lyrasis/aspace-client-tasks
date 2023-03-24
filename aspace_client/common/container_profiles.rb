module Common
  class ContainerProfiles < Thor
    desc 'get_container_profiles', 'retrieve API response of all container profile data in ASpace'
    def get_container_profiles
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('container_profiles', query: {page: page, page_size: 250})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('container_profiles', query: {page: page, page_size: 250})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_container_profiles_all_ids', 'retrieve API response of all container profie ids. returns an array of integers'
    def get_container_profiles_all_ids
      Aspace_Client.client.use_global_repository
      response = Aspace_Client.client.get('container_profiles', query: {all_ids: true})
      data = response.result
    end

    desc 'make_index FIELD', 'create the following index for container profiles - FIELD:uri. This is commonly used to embed container profile URIs in other record types'
    long_desc <<-LONGDESC
      @param field [String] name of the field that contains the unique values with which to create the hash keys
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

    desc 'attach_container_profiles DATA FIELD', 'attach container profiles refs to object by matching values from the given field'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to which to attach container profile URIs
      @param field [String] name of the field that contains the unique values with which to create the hash keys
      @return [Array<Hash>] DATA with embedded container profile URIs
    LONGDESC
    def attach_container_profiles(data,field)
      index = execute "common:container_profiles:make_index", [field]
      puts "attaching container profile URIs"
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        container_profiles_refs = record["container_profiles__refs"].nil? ? [] : record["container_profiles__refs"]
        container_profiles_refs << index[record[field]] unless record[field].nil?
        record["container_profiles__refs"] = container_profiles_refs
      end

      data
    end

    desc 'post_container_profiles DATA TEMPLATE', 'given data and template filename (no extension), ingest container_profiles via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to send to ASpace
      @param template [String] the name of the ERB template (without extension) to use
      @return [nil] posts data to ASpace
    LONGDESC
    def post_container_profiles(data,template)
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
