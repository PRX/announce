$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bottler'

require 'minitest/autorun'

Bottler.logger = Logger.new('/dev/null')
