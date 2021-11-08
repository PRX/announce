require "yaml"
require "erb"

module Announce
  class Configuration
    attr_reader :options

    def self.configure(options = {})
      opts = new(options).configure
      Announce.options.merge!(opts)
    end

    def self.default_options
      {}.tap do |defaults|
        if defined?(ActiveJob)
          defaults[:queue_name_prefix] = ::ActiveJob::Base.queue_name_prefix
          defaults[:queue_name_delimiter] =
            ::ActiveJob::Base.queue_name_delimiter
          defaults[:adapter] = aj_queue_adapter_name
        else
          defaults[:queue_name_prefix] =
            ENV["RAILS_ENV"] || ENV["APP_ENV"] || "development"
          defaults[:queue_name_delimiter] = "_"
          defaults[:adapter] = :inline
        end

        defaults[:app_name] = "app"
        defaults[:namespace] = "announce"
      end
    end

    def self.aj_queue_adapter_name
      ajqa = ::ActiveJob::Base.queue_adapter.name
      ajqa.match(/ActiveJob::QueueAdapters::(.*)Adapter/)[1].underscore
    end

    def initialize(options)
      @options = options
      base = defined?(Rails) ? Rails.root : Dir.pwd
      options[:config_file] ||= File.join(base, "config", "announce.yml")
    end

    def config_file
      options[:config_file]
    end

    def configure
      defaults = self.class.default_options
      if File.exist?(config_file)
        defaults.merge(
          YAML.load(ERB.new(IO.read(config_file)).result).symbolize_keys
        )
      else
        Announce.logger.warn "PubSub file #{config_file} does not exist"
        defaults
      end
    end
  end
end
