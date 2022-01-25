require_relative '../aspace_client'

class Chains < Thor

  # invoke has the limit that it can only run a method once during a command. This is intended.
  # The below method, execute, allows you to call a method multiple times. This is important
  # because there are methods that call other methods.
  # The syntax to use execute works exactly like invoke. The only minor difference is that you
  #  have to include all three parameters (empty arrays if you have nothing to pass)
  no_commands do 
    def execute(task, args, options)
      (klass, task) = Thor::Util.find_class_and_command_by_namespace(task)
      klass.new.invoke(task, args, options)
    end
  end

  desc 'example_save_chain', 'this represents a sample chain that results in saving output'
  def example_save_chain
    registry = execute 'registries:resources', [], []
    resources_subjects = execute 'common:objects:attach_subjects', [registry[:path],registry[:infile]], []
    execute 'registries:save', [registry[:path],'resources_out_subjects_test.json',resources_subjects], []
  end

  desc 'example_post_chain', 'this represents a sample chain that results in posting the output to the API'
  def example_post_chain
    registry = execute 'registries:resources', [], []
    resources_all = execute 'project_name:objects:attach_all_entities', [registry[:path],registry[:infile]], []
    execute 'registries:save', [registry[:path],'resources_out_allentities_test.json',resources_all], []
    execute 'common:objects:post_resources', [registry[:path],'resources_out_allentities_test.json','resources'], []
  end
end
