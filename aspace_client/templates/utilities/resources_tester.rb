require 'json'
require 'erb'

def get_data
  path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/aspace")
  data = JSON.parse(File.read(File.join(path,"resources_out_all.json")))
end

def get_template
  path = File.expand_path("~/Documents/migrations/aspace/asu-migration/asu-aspace-migration/lib/aspace_client/templates")
  template = File.read(File.join(path,"resources.json.erb"))
end

class Resource
  include ERB::Util
  attr_accessor :data, :template

  def initialize(data, template)
    @data = data
    @template = template
  end

  def render
    binded = ERB.new(@template).result(binding)
  end

  def save(file)
    path = File.expand_path("~/Documents/migrations/aspace/asu-migration/asu-aspace-migration/lib/aspace_client/templates//utilities/data")
    file_path = File.join(path,file)
    File.open(file_path, "w+") do |f|
      f.write(render)
    end
  end

end

resource = Resource.new(get_data[19], get_template)
resource.save('resource_templated.json')