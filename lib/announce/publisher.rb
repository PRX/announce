require 'shoryuken'
require 'announce'
require 'announce/message'

module Announce
  module Publisher
    def publish(subject, action, body, options = {})
      Announce.publish(subject, action, body, options)
    end
  end
end
