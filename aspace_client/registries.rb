class Registries < Thor

  desc 'resources', 'in and out registry for resources'
  def resources
    {
      :path => Aspace_Client.datadir,
      :log_path => Aspace_Client.log_path,
      :infile => 'resources_out.json',
      :outfile => 'resources_processed.json'
    }
  end

  desc 'get_json PATH, FILE', 'read JSON data from file'
  long_desc <<-LONGDESC
      @param path [String] path of file to read
      @param file [String] name of file to read
      @return [Array<Hash>] data
  LONGDESC
  def get_json(path,file)
    JSON.parse(File.read(File.join(path,file)))
  end

  desc 'get_csv PATH, FILE', 'read CSV from file'
  long_desc <<-LONGDESC
      @param path [String] path of file to read
      @param file [String] name of file to read
      @return [Array<Array<String>>] array of arrays that represent the CSV data
  LONGDESC
  def get_csv(path,file)
    CSV.read(File.join(path,file),encoding: "UTF-8")
  end

  desc 'save PATH, FILE, DATA', 'save JSON data to a file'
  long_desc <<-LONGDESC
      @param path [String] path to which to save DATA
      @param file [String] name to give the saved JSON file
      @param data [Array<String>] data to save
      @return [nil] saves CSV file
  LONGDESC
  def save(path, file, data)
    write_path = File.join(path, file)
    File.open(write_path,"w") do |f|
      f.write(data.to_json)
    end
  end

  desc 'json_to_csv PATH, FILE, DATA', 'convert json data to csv and save'
  long_desc <<-LONGDESC
      @param path [String] path to which to save the CSV file
      @param file [String] name to give the saved CSV file
      @param data [Array<String>] data to convert to CSV
      @return [nil] saves CSV file
  LONGDESC
  def json_to_csv(path, file, data)
    CSV.open(File.join(path,file), "w") do |csv|
      csv << data[0].keys
      data.each do |record|
        csv << record.values
      end
    end
  end

end