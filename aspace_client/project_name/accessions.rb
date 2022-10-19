module Project_Name
  class Accessions < Thor

    # adding as example instead of in common because the matcher is localized
    desc 'update_accessions_with_data DATA, ID', 'given a dataset and ID field, update existing accession records, matching on identifier'
    def update_accessions_with_data(data,id)
      puts "making index..."
      index = execute 'common:accessions:make_index_accessions'
      puts "getting accessions..."
      accessions = execute 'common:accessions:get_accessions'
      log_path = Aspace_Client.log_path
      error_log = []

      puts "updating accessions..."
      accessions.each do |accession|
        # find the first occurrence of a match then move on
        matching_data = data.lazy.select {|record| [record['accessno0'],record['accessno1'],record['accessno2'],record['accessno3']] == [accession['id_0'],accession['id_1'],accession['id_2'],accession['id_3']]}.first(1)
        # binding.pry
        # turn the hash into templated json
        json = ArchivesSpace::Template.process(:accessions,matching_data[0])
        # turn it back into a hash so you can merge it with the API data
        templated_data = JSON.parse(json)
        accession.merge!(templated_data)
        # breaking up the record's uri so you can programmatically post to the appropriate record
        ref_split = index[[accession['id_0'],accession['id_1'],accession['id_2'],accession['id_3']]].split('/')
        response = Aspace_Client.client.post("#{ref_split[3]}/#{ref_split[4]}",accession.to_json)
        puts response.result.success? ? "=) #{accessions.length - (accessions.find_index(accession) + 1)} to go" : response.result
        error_log << response.result if response.result.success? == false
      end

      write_path = File.join(log_path,"update_accessions_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end

    end
    
  end
end
