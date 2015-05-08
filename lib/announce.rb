require 'announce/version'
require 'announce/core_ext'
require 'announce/configuration'
require 'logger'

module Announce
  class << self
    def options
      @options ||= default_options
    end

    def configure(opts = {})
      Announce::Configuration.configure(opts)
      yield @options if block_given?
    end

    def configure_broker
      adapter_constantize(:broker_manager).new(options).configure
    end

    def default_options
      {}.tap do |defaults|
        if defined?(ActiveJob)
          defaults[:name_prefix] = ::ActiveJob::Base.queue_name_prefix
          defaults[:name_delimiter] = ::ActiveJob::Base.queue_name_delimiter
          defaults[:adapter] = ::ActiveJob::Base.queue_adapter
        else
          defaults[:name_prefix] = ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
          defaults[:name_delimiter] = '_'
          defaults[:adapter] = :inline
        end
      end
    end

    def topic(subject, action, options = {})
      adapter_constantize(:topic).new(subject, action, options)
    end

    def subscribe_worker(worker_class, subject, actions=[], options={})
      adapter_constantize(:subscriber).new.subscribe(worker_class, subject, actions, options)
    end

    def adapter_constantize(name)
      adapter = Announce.options[:adapter]
      require "announce/adapters/#{adapter}_adapter"
      "::Announce::Adapters::#{adapter.to_s.camelize}Adapter::#{name.to_s.camelize}".constantize
    end

    def logger
      @logger ||= if defined?(Rails)
        Rails.logger
      else
        Logger.new(STDOUT)
      end
    end

    def logger=(l)
      @logger = l
    end
  end
end
