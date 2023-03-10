require 'erb'
require 'json'

# Provides tools for testing ERB templates.
class Templater
  include ERB::Util

  attr_accessor :outpath, :inpath, :tempath, :infile, :outfile, :template

  # @param infile [String] The name of the file which contains the data to templatize.
  # @param outfile [String] The name of the file to output after templatizing.
  # @param template [String] The name (without extension) of the template file to use to process the record.
  def initialize(infile:, outfile:, template:)
    @outpath = File.expand_path("./aspace_client/templates/utilities/data")
    @inpath = File.expand_path("../data/endpoint")
    @tempath = File.expand_path("./aspace_client/templates")
    @infile = infile
    @outfile = outfile
    @template = "#{template}.json.erb"
  end

  # @return [Array<Hash>] returns an array of hashes that reflects the `@infile` JSON data.
  def get_data
    JSON.parse(File.read(File.join(@inpath, @infile)))
  end

  # @return [String] returns the contents of the template file.
  def get_template
    File.read(File.join(@tempath, @template))
  end

  # Transforms data from `@infile` using the provided `@template` using ERB.
  # 
  # @param data [Array<Hash>] the data to pass through the ERB template.
  # @return [JSON] the templated data.
  def render(data)
    ERB.new(get_template).result(binding)
  end

  # Runs the data through #render and then saves the templated data as `@outfile`.
  # 
  # @param data [Array<Hash>] The data to pass through the ERB template.
  # @return [nil] Saves the templated data as `@outfile`.
  def save(data)
    file_path = File.join(@outpath, @outfile)
    File.open(file_path, "w+") do |f|
      f.write(render(data))
    end
  end

  # Runs a record through the indicated ERB template and saves to file.
  #   By default this method will take the first record in the provided data.
  #   However, you can customize this using the params.
  # 
  # @param select_or_reject [Lambda, nil] Any set of logic that subsets the data.
  # @param index [Integer, 0] The index of the record you want to target.
  # @return [nil] Saves the templated data as `@outfile`.
  def templatize_single(select_or_reject: nil, index: 0)
    data = get_data
    data = select_or_reject.nil? ? data[index] : select_or_reject.call(data)[index]

    save(data)
  end
end
