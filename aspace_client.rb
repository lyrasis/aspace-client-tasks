require 'archivesspace/client'
require 'dotenv/load'
require 'thor'
require 'json'
require 'stringio'
require 'csv'
require_relative './aspace_client/mixins'

# dev
require 'pry'

# monkey-patching Thor class to include a mixin
# the mixin adds the execute method to all Thor-inherited classes
class Thor
  include Mixins
end

module Aspace_Client
  # this is your default directory for data files  
  @@datadir = File.expand_path("../data/for-import")
  def self.datadir
    @@datadir
  end
  # this is your default directory for log files
  @@log_path = File.expand_path("../data/api_logs")
  def self.log_path
    @@log_path
  end

  @@config = ArchivesSpace::Configuration.new({
    # set the base uri for your ArchivesSpace API instance
    base_uri: 'http://localhost:8089',
    username: ENV['ASPACE_USERNAME'],
    password: ENV['ASPACE_PASS'],
    page_size: 50,
    throttle: 0,
    verify_ssl: true,
  })
  begin
    @@client = ArchivesSpace::Client.new(@@config).login
  rescue SystemCallError
    p "Unable to connect to ArchivesSpace. Make sure your instance is running and your Aspace_Client.config is correct."
  else
    # if you want, set the default ArchivesSpace repository you want to connect to
    @@client.config.base_repo = "repositories/2"
    def self.client
      @@client
    end
  end


  # Require all application files, excluding any in the templates folder
  Dir.glob("#{__dir__}/aspace_client/**/*").sort.select{ |path| path.match?(/\.rb$/) }.each do |rbfile|
    require_relative rbfile.delete_prefix("#{File.expand_path(__dir__)}/").delete_suffix('.rb') unless rbfile =~ /\/templates\//
  end
end