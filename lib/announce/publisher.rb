require "shoryuken"
require "announce/message"

module Announce
  module Publisher
    def publish(subject, action, body, options = {})
      Announce.publish(subject, action, body, options)
    end

    alias announce publish
  end
end
