require 'json'
require 'erb'

# This script will run every record in a data file through the aos template. This is meant to catch breaking erros - it's not
# meant to output a sample file for each record.

def get_data(path,file)
  data = JSON.parse(File.read(File.join(path,file)))
end

def get_template(path,file)
  template = File.read(File.join(path,file))
end

class Record
  include ERB::Util
  attr_accessor :data, :template

  def initialize(data, template)
    @data = data
    @template = template
  end

  def render
    binded = ERB.new(@template).result(binding)
  end

  def save(path,file)
    file_path = File.join(path,file)
    File.open(file_path, "w+") do |f|
      f.write(render)
    end
  end

end

in_path = File.expand_path("~/Path/To/Project/Data/File")
out_path = File.expand_path("~/Path/To/Project/aspace-client-tasks/aspace_client/templates/utilities/data")
template_path = File.expand_path("~/Path/To/Project/aspace-client-tasks/aspace_client/templates")

data = get_data(in_path,'items_with_attachments.json')
data.each_with_index do |item,index|
  puts "processing record #{index}"

  record = Record.new(item,get_template(template_path,'aos.json.erb'))

  record.save(out_path,'aos_templated.json')
end