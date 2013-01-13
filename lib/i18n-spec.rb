require "yaml"

if defined?(Psych) and defined?(Psych::VERSION) and !defined?(YAML::ParseError)
  YAML::ParseError = Psych::SyntaxError
end

require 'iso'

require File.dirname(__FILE__) + '/i18n-spec/locale_file.rb'
