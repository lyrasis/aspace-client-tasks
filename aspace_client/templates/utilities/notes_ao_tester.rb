require 'json'
require 'erb'

def get_data
  path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/aspace")
  data = JSON.parse(File.read(File.join(path,"notes_out.json")))
end

def get_template
  path = File.expand_path("~/Documents/migrations/aspace/asu-migration/asu-aspace-migration/lib/aspace_client/templates")
  template = File.read(File.join(path,"notes_ao.json.erb"))
end

class Note_AO
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

# selected_data = get_data.select {|record| record['objectid'] == "VC-OH-Christburg,Sheyann1"}
# note_ao = Note_AO.new(selected_data[0], get_template)
note_ao = Note_AO.new(get_data[0], get_template)
note_ao.save('note_ao_templated.json')