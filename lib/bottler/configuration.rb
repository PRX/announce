require 'yaml'
require 'erb'

module Bottler
  class Configuration
    attr_reader :options

    def self.configure(options={})
      opts = new(options).configure
      Bottler.options.merge!(opts)
    end

    def initialize(options)
      @options = options
      base = defined?(Rails) ? Rails.root : Dir.pwd
      options[:pub_sub_file] ||= File.join(base, 'config', 'pub_sub.yml')
    end

    def pub_sub_file
      options[:pub_sub_file]
    end

    def configure
      if File.exist?(pub_sub_file)
        YAML.load(ERB.new(IO.read(pub_sub_file)).result).deep_symbolize_keys
      else
        Bottler.logger.warn "PubSub file #{pub_sub_file} does not exist"
        {}
      end
    end
  end
end
