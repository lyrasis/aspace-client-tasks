class Registries < Thor

  desc 'resources', 'in and out registry for resources'
  def resources
    registry = {
      :path => Aspace_Client.datadir,
      :log_path => Aspace_Client.log_path,
      :infile => 'resources_out.json',
      :outfile => 'resources_processed.json'
    }
    
  end

  desc 'get_json PATH, FILE', 'read JSON data from file'
  def get_json(path,file)
    data = JSON.parse(File.read(File.join(path,file)))
  end

  desc 'save PATH, FILE, DATA', 'save data to a file'
  def save(path, file, data)
    write_path = File.join(path, file)
    File.open(write_path,"w") do |f|
      f.write(data.to_json)
    end
  end

end