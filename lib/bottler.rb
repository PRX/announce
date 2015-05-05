require 'bottler/version'
require 'bottler/core_ext'
require 'logger'

module Bottler
  class << self
    def options
      @options ||= default_options
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

    def default_options
      {}.tap do |defaults|
        if defined?(ActiveJob)
          defaults[:destination_name_prefix] = ::ActiveJob::Base.queue_name_prefix
          defaults[:destination_name_delimiter] = ::ActiveJob::Base.queue_name_delimiter
        else
          defaults[:destination_name_prefix] = ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
          defaults[:destination_name_delimiter] = '_'
        end
      end
    end
  end
end
