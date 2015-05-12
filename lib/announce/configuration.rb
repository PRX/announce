require 'yaml'
require 'erb'

module Announce
  class Configuration
    attr_reader :options

    def self.configure(options={})
      opts = new(options).configure
      Announce.options.merge!(opts)
    end

    def initialize(options)
      @options = options
      base = defined?(Rails) ? Rails.root : Dir.pwd
      options[:config_file] ||= File.join(base, 'config', 'announce.yml')
    end

    def config_file
      options[:config_file]
    end

    def configure
      if File.exist?(config_file)
        YAML.load(ERB.new(IO.read(config_file)).result).deep_symbolize_keys
      else
        Announce.logger.warn "PubSub file #{config_file} does not exist"
        {}
      end
    end
  end
end
