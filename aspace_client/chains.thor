require_relative '../aspace_client'

class Chains < Thor

  desc 'example_save_chain', 'this represents a sample chain that results in saving output'
  def example_save_chain
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    data = execute 'common:subjects:attach_subjects', [data,"subjects"]
    execute 'registries:save', [registry[:path],'resources_out_subjects_test.json',data]
  end

  desc 'example_post_chain', 'this represents a sample chain that results in posting the output to the API'
  def example_post_chain
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    data = execute 'common:subjects:attach_subjects', [data,"subjects"]
    execute 'common:objects:post_resources', [data,'resources']
  end
end
