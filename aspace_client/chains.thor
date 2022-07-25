require_relative '../aspace_client'

class Chains < Thor

  # invoke has the limit that it can only run a method once during a command. This is intended.
  # The below method, execute, allows you to call a method multiple times. This is important
  # because there are methods that call other methods.
  # The syntax to use execute works exactly like invoke.
  no_commands do 
    def execute(task, args = [], options = [])
      (klass, task) = Thor::Util.find_class_and_command_by_namespace(task)
      klass.new.invoke(task, args, options)
    end
  end

  desc 'example_save_chain', 'this represents a sample chain that results in saving output'
  def example_save_chain
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    resources_subjects = execute 'common:subjects:attach_subjects', [data,"subjects"]
    execute 'registries:save', [registry[:path],'resources_out_subjects_test.json',resources_subjects]
  end

  desc 'example_post_chain', 'this represents a sample chain that results in posting the output to the API'
  def example_post_chain
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    resources_subjects = execute 'common:subjects:attach_subjects', [data,"subjects"]
    execute 'common:objects:post_resources', [resources_subjects,'resources']
  end
end
