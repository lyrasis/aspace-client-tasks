require 'json'
require 'erb'

def get_data
  path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/aspace")
  data = JSON.parse(File.read(File.join(path,"ao_out_resource_ids_all_with_resource_id_resources.json")))
end

def get_template
  path = File.expand_path("~/Documents/migrations/aspace/asu-migration/asu-aspace-migration/lib/aspace_client/templates")
  template = File.read(File.join(path,"aos.json.erb"))
end

class Aos
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

selection = get_data.select {|record| record['component_id'] == "Lewis, R-2007-box 1"}

aos = Aos.new(selection[0], get_template)
# aos = Aos.new(get_data[19], get_template)
aos.save('aos_templated.json')