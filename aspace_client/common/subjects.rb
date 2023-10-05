module Common
  class Subjects < Thor
    desc 'get_subjects', 'retrieve API response of all subject data in ASpace'
    def get_subjects
      Aspace_Client.client.use_global_repository
      page = 1
      data = []
      response = Aspace_Client.client.get('subjects', query: {page: page})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('subjects', query: {page: page})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_subjects_all_ids', 'retrieve API response of all subjects ids. returns an array of integers'
    def get_subjects_all_ids
      Aspace_Client.client.use_global_repository
      response = Aspace_Client.client.get('subjects', query: {all_ids: true})
      response.result
    end

    desc 'make_index', 'create the following index - "title:uri"'
    def make_index
      data = execute 'common:subjects:get_subjects'
      index = {}
      data.each do |record|
        index[record['title'].gsub(" -- ", "--")] = record['uri']
      end
      index
    end

    desc "attach_subjects", "attach subjects refs to object by matching values from the given field"
    long_desc <<-LONGDESC
      This method assumes that the field values are contained in an array. 

      @param data [Array<Hash>] the data to which to attach subject URIs 
      @param fields [String or Array] name of the fields that contain the values with which to attach subject URIs
      @return [Array<Hash>] data with subject URIs attached
    LONGDESC
    def attach_subjects(data, fields)
      index = execute "common:subjects:make_index"
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        subjects_refs = record["subjects__refs"].nil? ? [] : record["subjects__refs"]
        [fields].flatten.each do |field|
          record[field].each { |entity| subjects_refs << index[entity] }
        end
        record["subjects__refs"] = subjects_refs
      end

      data
    end

    desc 'post_subjects DATA, TEMPLATE', 'given data and template filename (no extension), ingest subjects via the ASpace API'
    long_desc <<-LONGDESC
      @param data [Array<Hash>] the data to post 
      @param template [String] the name of the template file without file extension
      @return [nil] sends data to API. If there's an error, instead sends error to log file
    LONGDESC
    def post_subjects(data, template)
      Aspace_Client.client.use_global_repository

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template, row)
        response = Aspace_Client.client.post('subjects', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_subjects_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'delete_subjects', 'delete all subjects via API'
    def delete_subjects
      Aspace_Client.client.use_global_repository
      # shape: [1,2,3]
      data = execute 'common:subjects:get_subjects_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("subjects/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end
  end
end
