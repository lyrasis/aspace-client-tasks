module Mixins
  def execute(task, args = [], options = [])
    (klass, task) = Thor::Util.find_class_and_command_by_namespace(task)
    klass.new.invoke(task, args, options)
  end

end