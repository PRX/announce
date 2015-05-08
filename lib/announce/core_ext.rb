begin
  require 'active_support/core_ext/hash/keys'
  require 'active_support/core_ext/hash/deep_merge'
  require 'active_support/core_ext/hash/slice'
rescue LoadError
  class Hash
    def stringify_keys
      keys.each do |key|
        self[key.to_s] = delete(key)
      end
      self
    end if !{}.respond_to?(:stringify_keys)

    def symbolize_keys
      keys.each do |key|
        self[(key.to_sym rescue key) || key] = delete(key)
      end
      self
    end if !{}.respond_to?(:symbolize_keys)

    def deep_symbolize_keys
      keys.each do |key|
        value = delete(key)
        self[(key.to_sym rescue key) || key] = value

        value.deep_symbolize_keys if value.is_a? Hash
      end
      self
    end if !{}.respond_to?(:deep_symbolize_keys)

    def slice(*keys)
      keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
      keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
    end
  end
end

begin
  require 'active_support/core_ext/string/inflections'
rescue LoadError
  class String
    def constantize
      names = self.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
  end if !"".respond_to?(:constantize)

  class String
    def camelize
      string = self
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!(/\//, '::')
      string
    end
  end if !"".respond_to?(:camelize)
end
