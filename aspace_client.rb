require 'archivesspace/client'
require 'dotenv/load'
require 'thor'
require 'json'
require 'stringio'
require 'csv'

# dev
require 'pry'

module Aspace_Client
    
  @@datadir = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/aspace')
  def self.datadir
    @@datadir
  end

  @@log_path = File.expand_path("~/Documents/migrations/aspace/asu-migration/data/api_logs")
  def self.log_path
    @@log_path
  end

  @@config = ArchivesSpace::Configuration.new({
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