require "logger"

require "announce/configuration"
require "announce/core_ext"
require "announce/message"
require "announce/publisher"
require "announce/subscriber"
require "announce/version"
require "announce/railtie" if defined?(Rails)

module Announce
  class << self
    def publish(subject, action, message, options = {})
      adapter_class.publish(subject, action, message, options)
    end

    alias announce publish

    def subscribe(worker_class, subject, actions = [], options = {})
      adapter_class.subscribe(worker_class, subject, actions, options)
    end

    def configure_broker(opts = {})
      adapter_class.configure_broker(options.merge(opts))
    end

    def options
      @options ||= Announce::Configuration.default_options
    end

    def configure(opts = {})
      Announce::Configuration.configure(opts)
      yield @options if block_given?
    end

    def adapter_class
      announce_adapter = Announce.options[:adapter]
      require "announce/adapters/#{announce_adapter.to_s.downcase}_adapter"
      "::Announce::Adapters::#{announce_adapter.to_s.camelize}Adapter"
        .constantize
    end

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def logger=(l)
      @logger = l
    end
  end
end
