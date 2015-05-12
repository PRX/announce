require 'logger'

require 'announce/configuration'
require 'announce/core_ext'
require 'announce/message'
require 'announce/publisher'
require 'announce/subscriber'
require 'announce/version'
require 'announce/railtie' if defined?(Rails)

module Announce
  class << self

    def publish(subject, action, message, options={})
      adapter_class.publish(subject, action, message, options)
    end

    def subscribe(worker_class, subject, actions = [], options = {})
      adapter_class.subscribe(worker_class, subject, actions, options)
    end

    def configure_broker
      adapter_class.configure_broker(options)
    end

    def options
      @options ||= default_options
    end

    def configure(opts = {})
      Announce::Configuration.configure(opts)
      yield @options if block_given?
    end

    def default_options
      {}.tap do |defaults|
        if defined?(ActiveJob)
          defaults[:name_prefix] = ::ActiveJob::Base.queue_name_prefix
          defaults[:name_delimiter] = ::ActiveJob::Base.queue_name_delimiter
          defaults[:adapter] = aj_queue_adapter_name
        else
          defaults[:name_prefix] = ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
          defaults[:name_delimiter] = '_'
          defaults[:adapter] = :inline
        end
      end
    end

    def aj_queue_adapter_name
      ajqa = ::ActiveJob::Base.queue_adapter.name
      ajqa.match(/ActiveJob::QueueAdapters::(.*)Adapter/)[1].underscore
    end

    def adapter_class
      announce_adapter = Announce.options[:adapter]
      require "announce/adapters/#{announce_adapter.to_s.downcase}_adapter"
      "::Announce::Adapters::#{announce_adapter.to_s.camelize}Adapter".constantize
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
