module Common
  class Accessions < Thor

    desc 'get_accessions', 'retrieve API response of all accessions data in ASpace'
    def get_accessions(*args)
      page = 1
      data = []
      response = Aspace_Client.client.get('accessions', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('accessions', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end


    desc 'get_accessions_all_ids', 'retrieve API response of all accessions ids. returns an array of integers'
    def get_accessions_all_ids(*args)
      response = Aspace_Client.client.get('accessions', query: {all_ids: true})
      data = response.result
    end

    desc 'delete_accessions', 'delete all accessions via API'
    def delete_accessions
      # shape: [1,2,3]
      data = invoke 'get_accessions_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("accessions/#{id}")
        puts response.result.success? ? '=)' : response.result
      end
    end

    desc 'make_index_accessions', 'create the following index - "id:uri". id is an array of id_0, id_1, id_2, and id_3'
    def make_index_accessions
      data = invoke 'common:accessions:get_accessions'
      index = {}
      data.each do |record|
        index[[record['id_0'],record['id_1'],record['id_2'],record['id_3']]] = record['uri']
      end
      index
    end

    desc 'post_accessions DATA, TEMPLATE', 'given data and template filename (no extension), ingest accessions via the ASpace API'
    def post_accessions(data,template)

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []
      
      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('accessions', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end

      File.open(File.join(log_path,"post_accessions_error_log.txt"), "w") do |f|
        f.write(error_log.join(",\n"))
      end

    end

    desc 'turn_on_access_restrictions', 'update "access restrictions" to "true" for all Accessions'
    def turn_on_access_restrictions
      accessions = execute 'common:accessions:get_accessions'
      accessions.each_with_index do |accession,index|
        accession['access_restrictions'] = true
        ref_split = accession['uri'].split('/')
        response = Aspace_Client.client.post("#{ref_split[3]}/#{ref_split[4]}",accession.to_json)
        puts response.result.success? ? "=)" : response.result
        puts "done!" if index == accessions.length - 1
      end

    end
    
  end
end
