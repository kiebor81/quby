# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/quby'

class ExtensionSystemTest < Minitest::Test
  def setup
    # Remove any previously loaded extensions by getting a fresh Query class
    # Note: In real usage, extensions are loaded once at app startup
  end

  def test_use_extensions_with_single_extension
    # Create a simple test extension
    test_extension = Module.new do
      def test_method
        'extension_loaded'
      end
    end

    Quby.use_extensions(test_extension)
    
    query = Quby::Query.new
    assert_respond_to query, :test_method
    assert_equal 'extension_loaded', query.test_method
  end

  def test_use_extensions_with_multiple_extensions
    ext1 = Module.new do
      def ext1_method
        'ext1'
      end
    end

    ext2 = Module.new do
      def ext2_method
        'ext2'
      end
    end

    Quby.use_extensions(ext1, ext2)
    
    query = Quby::Query.new
    assert_respond_to query, :ext1_method
    assert_respond_to query, :ext2_method
    assert_equal 'ext1', query.ext1_method
    assert_equal 'ext2', query.ext2_method
  end

  def test_use_extensions_with_array
    ext1 = Module.new do
      def array_ext1
        'a1'
      end
    end

    ext2 = Module.new do
      def array_ext2
        'a2'
      end
    end

    Quby.use_extensions([ext1, ext2])
    
    query = Quby::Query.new
    assert_respond_to query, :array_ext1
    assert_respond_to query, :array_ext2
  end

  def test_extension_can_override_existing_methods
    override_ext = Module.new do
      def select(*columns)
        @custom_select_called = true
        super
      end
      
      attr_reader :custom_select_called
    end

    Quby.use_extensions(override_ext)
    
    query = Quby::Query.new.from('users')
    query.select('id', 'name')
    
    assert query.custom_select_called
  end
end
