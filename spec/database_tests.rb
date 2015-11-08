require 'minitest/autorun'
require 'yaml'
require_relative '../lib/simstore.rb'

class SimStoreTest < Minitest::Test

  SCHEMA = YAML.load_file("../config/db_schema.yml")

  def setup
    @config = {
      :db_name => 'test'
    }
    @test_store = SimStore.new(@config)
    populate_everything(@test_store)
  end

  def populate_everything(store)
    store.populate_vendors
    store.populate_employees
    store.populate_products
    store.populate_transactions
  end

  def test_named_db_is_created
    assert_equal 'test', @test_store.db_name.match('test')[0]
    assert_equal true, File.exist?(@test_store.db_name)
  end

  def test_random_db_is_created
    s = SimStore.new
    assert_equal true, File.exist?(s.db_name)
  end

  def test_db_can_be_deleted
    s = SimStore.new
    assert_equal true, File.exist?(s.db_name)
    s.db_down
    refute_equal true, File.exist?(s.db_name)
  end

  def test_db_tables_are_created
    tables_exist = [].tap do |arr|
      SCHEMA.each do |table|
        arr << ( @test_store.db.connection.table_exists? table[0] )
      end
    end
    assert_equal true, tables_exist.all?
  end

  def test_clean_database
    s = SimStore.new
    populate_everything(s)
    s.clean_database
  end

  def clean_table
    s = SimStore.new
    populate_everything(s)
    s.clean_table("products")
    assert_equal true, Models::Employee.take(1).empty?
  end
end
