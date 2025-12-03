# frozen_string_literal: true

require_relative 'test_helper'

class VersionTest < Minitest::Test
  def test_version_constant_exists
    assert defined?(QueryKit::VERSION)
  end

  def test_version_is_string
    assert_instance_of String, QueryKit::VERSION
  end

  def test_version_format
    assert_match(/\d+\.\d+\.\d+/, QueryKit::VERSION)
  end
end
