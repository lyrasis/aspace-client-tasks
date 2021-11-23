require_relative '../aspace_client'
require 'pry'

module Aspace_Client
  class Chains < Thor

    desc 'example_chain', 'this represents a sample chain'
    def example_chain
      registry = invoke 'aspace_client:registries:resources'
      resources_all = invoke 'aspace_client:objects:attach_all_entities', [registry[:path],registry[:infile]], []
      invoke 'aspace_client:registries:save', [registry[:path],'resources_out_allentities_test.json',resources_all], []
    end

  end
end