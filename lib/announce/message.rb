require 'securerandom'
require 'json'

module Announce
  class Message

    attr_accessor :options

    def initialize(options={})
      @options = {
        'message_id' => ::SecureRandom.uuid,
        'app' => app,
        'sent_at' => Time.now.utc
      }.merge(options).stringify_keys
    end

    def app
      Announce.options[:app_name]
    end

    def to_message
      options.stringify_keys
    end

    def to_json
      options.to_json
    end
  end
end
