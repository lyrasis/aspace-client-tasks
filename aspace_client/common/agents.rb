module Common
  class Agents < Thor
    # setting up DRY methods for agents
    %w(corporate_entities families people).each do |agent_type|
      # sets up get_all_ids method for each agent type
      desc "get_#{agent_type}_all_ids", "retrieve API response of all #{agent_type} ids. returns an array of integers"
      define_method("get_#{agent_type}_all_ids") do
        Aspace_Client.client.use_global_repository
        response = Aspace_Client.client.get("agents/#{agent_type}", query: {all_ids: true})
        data = response.result
      end
      # sets up delete method for each agent type
      desc "delete_#{agent_type}", "delete all #{agent_type} via API"
      define_method("delete_#{agent_type}") do
        Aspace_Client.client.use_global_repository
        data = invoke "get_#{agent_type}_all_ids"
        puts "deleting #{data.length} #{agent_type}"
        data.each do |id|
          response = Aspace_Client.client.get("agents/#{agent_type}/#{id}")
          record = response.result
          if record['is_user'] || record['is_repo_agent']
            puts "skipping agent that is a user"
          else
            response = Aspace_Client.client.delete("agents/#{agent_type}/#{id}")
            puts response.result.success? ? "=) #{data.length - data.find_index(id) - 1} to go" : response.result
          end    
        end
      end
      # sets up get method for each agent type
      desc "get_#{agent_type}", "retrieve API response of all #{agent_type} name data in ASpace"
      define_method("get_#{agent_type}") do
        Aspace_Client.client.use_global_repository
        page = 1
        data = []
        response = Aspace_Client.client.get("agents/#{agent_type}", query: {page: page, page_size: 100})
        last_page = response.result['last_page']
        while page <= last_page
          response = Aspace_Client.client.get("agents/#{agent_type}", query: {page: page, page_size: 100})
          data << response.result['results']
          page += 1
        end
        data.flatten
      end
      # sets up post method for each agent type
      desc "post_#{agent_type} DATA, TEMPLATE", "given data and template filename (no extension), ingest #{agent_type} names via the ASpace API"
      define_method("post_#{agent_type}") do |data,template|
        Aspace_Client.client.use_global_repository

        # setting up error log
        log_path = Aspace_Client.log_path
        error_log = []

        data.each do |row|
          json = ArchivesSpace::Template.process(template.to_sym, row)
          response = Aspace_Client.client.post("agents/#{agent_type}", json)
          puts response.result.success? ? "=) #{data.length - (data.find_index(row) - 1)} to go" : response.result
          error_log << response.result if response.result.success? == false
        end
        write_path = File.join(log_path,"post_#{agent_type}_error_log.txt")
        File.open(write_path,"w") do |f|
          f.write(error_log.join(",\n"))
        end
      end
      # sets up make_index method for each agent type
      desc "make_index_#{agent_type}", 'create the following index - "title:uri"'
      define_method("make_index_#{agent_type}") do
        data = invoke "get_#{agent_type}"
        index = {}
        data.each do |record|
          index[record['title']] = record['uri']
        end
        index
      end

    end

    desc 'DEPRECATED publish_all_agents', 'Will be removing this method in the next major release. Instead, use chains if you want the same functionality. publish all agents in an ASpace instance, except any agent that has the key "is_user"'
    def publish_all_agents
      people = invoke 'get_people'
      corporate = invoke 'get_corporate'
      families = invoke 'get_families'

      people.each do |person|
        unless person.keys.include? "is_user"
          response = Aspace_Client.client.post("#{person['uri']}/publish",'')
          puts response.result.success? ? '=)' : response.result
        end
      end

      corporate.each do |corporate_entity|
        unless corporate_entity.keys.include? "is_user"
          response = Aspace_Client.client.post("#{corporate_entity['uri']}/publish",'')
          puts response.result.success? ? '=)' : response.result
        end
      end

      families.each do |family|
        unless family.keys.include? "is_user"
          response = Aspace_Client.client.post("#{family['uri']}/publish",'')
          puts response.result.success? ? '=)' : response.result
        end
      end
    end

  end
end
