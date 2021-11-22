require 'archivesspace/client'
require 'dotenv/load'
require 'thor'
require 'json'
# require_relative 'aspace_client/classifications'

require 'pry'

module Aspace_Client
    
  @@datadir = File.expand_path('~/Documents/migrations/aspace/asu-migration/data/aspace')
  def self.datadir
    @@datadir
  end

  @@config = ArchivesSpace::Configuration.new({
    base_uri: 'http://localhost:8089',
    username: ENV['ASPACE_USERNAME'],
    password: ENV['ASPACE_PASS'],
    page_size: 50,
    throttle: 0,
    verify_ssl: true,
  })

  @@client = ArchivesSpace::Client.new(@@config).login
  # @@client.config.base_repo = "repositories/2"
  def self.client
    @@client
  end

  # @@client = ArchivesSpace::Client.new.login
  # def self.client
  #   @@client
  # end

  # Require all application files
  # Dir.glob("#{__dir__}/aspace_client/**/*").sort.select{ |path| path.match?(/\.thor$/) }.each do |rbfile|
  #   require_relative rbfile.delete_prefix("#{File.expand_path(__dir__)}/").delete_suffix('.thor')
  # end

  # Dir.glob("#{__dir__}/aspace_client/**/*").sort.select{ |path| path.match?(/\.rb$/) }.each do |rbfile|
  #   require_relative rbfile.delete_prefix("#{File.expand_path(__dir__)}/").delete_suffix('.rb')
  # end
end