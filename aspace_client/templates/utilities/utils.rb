require_relative "templater"

class Utils < Thor
  option :infile, :desc => "[String] The name of the file which contains the data to templatize.", aliases: "-i"
  option :outfile, :desc => "[String] The name of the file to output after templatizing.", aliases: "-o"
  option :template, :desc => "[String] The name (without extension) of the template file to use to process the record.", aliases: "-t"
  desc "templatize --infile --outfile --template", "Outputs templated data to utilities/data. Filepaths are defined in templater.rb"
  long_desc <<-LONGDESC
    In addition to the listed options, filepaths are defined in `templater.rb`. When setting up first time, make sure the paths are defined.
      The default paths work if you're running the task from the aspace-client-tasks directory.
  LONGDESC
  def templatize
    templater = Templater.new(infile: options[:infile], outfile: options[:outfile], template: options[:template])

    templater.templatize_single
  end
end
