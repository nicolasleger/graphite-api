$:.unshift File.expand_path("../../lib",__FILE__)

if ENV['with_coverage']
  require 'simplecov'
  require 'simplecov-rcov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
       SimpleCov::Formatter::HTMLFormatter.new.format(result)
       SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end

  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
  SimpleCov.start { add_filter "/tests/" }
end

gem 'minitest'
require 'minitest'
require 'minitest/autorun'
require "mocha/mini_test"

require_relative "../lib/graphite-api"

module GraphiteAPI
  module Unit
    class TestCase < Minitest::Test
    end
  end
  class Zscheduler
    def self.every(*);end
  end
end
