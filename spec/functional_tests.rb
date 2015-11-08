require 'minitest/autorun'
require_relative '../lib/simstore.rb'
require_relative 'randomconfig.rb'

class SimStoreTest < Minitest::Test
  include RandomConfig

  def setup
    # Setup a store object using random config
    @config = RandomConfig.new.config
    @config.each { |k, v| instance_variable_set("@#{k}", v) }
    @test_store = SimStore.new(@config)
    @test_store.populate_stock
    @test_store.run_business_day
    puts start_message
  end

  def start_message
    "New store: #{@unique_items} items, #{@min_stock_per_item} to " +
    "#{@max_stock_per_item} of each item; #{@max_daily_transactions} " +
    "transactions; date: #{@date.to_s[0..9]}"
  end

  def test_input_failure_non_integers
    @config.each_key do |option|
      assert_raises(ArgumentError) { SimStore.new(option => 3.14) }
      assert_raises(ArgumentError) { SimStore.new(option => "monkey") }
    end
  end

  def test_input_failure_non_date_object
    assert_raises(ArgumentError) { SimStore.new(:date => "10/23/2016") }
  end

  def test_input_failure_max_less_than_min
    assert_raises(ArgumentError) {
      SimStore.new(:min_stock_per_item => 20, :max_stock_per_item => 5)
    }
  end

  def test_warning_on_inadvisable_input
    out = capture_io do
      SimStore.new(:unique_items => 5, :max_stock_per_item => 3,
        :min_stock_per_item => 1, :max_daily_transactions => 50)
    end
    assert_match /Warning/, out[1]
  end

  def test_items_have_required_form
    item = SimStore.new.make_item
    assert_instance_of Array, item
    assert_equal 4, item.length
    assert_instance_of String, item[0]
    assert_instance_of String, item[1]
    assert_instance_of String, item[2]
    assert_instance_of Fixnum, item[3]
  end

  def test_number_of_items
    skip
    assert_equal @unique_items, @test_store.count_items
  end

  def test_stock_size_within_bounds
    skip
    c = RandomConfig.new.config
    store = SimStore.new(c)
    store.populate_stock
    size = store.count_items
    min = c[:unique_items] * c[:min_stock_per_item]
    max = c[:unique_items] * c[:max_stock_per_item]
    assert(size.between?( min, max ))
  end

  def test_all_skus_are_unique
    skip
    skus = @test_store.count_skus
    assert_equal skus.length, skus.uniq.length
  end

  def test_buying_an_item_decrements_stock
    skip
    if @test_store.count_items == 0
      puts "No items in stock. Skipping this test."
    else
      sku, before = nil, nil
      loop do
        sku = @test_store.get_random_item
        before = @test_store.get_stock(sku)
        break if @test_store.buy_item(sku)
      end
      after = @test_store.get_stock(sku)
      assert_equal after, ( before - 1 )
    end
  end

  def test_buying_an_item_updates_ledger
    skip
    if @test_store.count_items == 0
      puts "No items in stock. Skipping this test."
    else
      sku, price, before = nil, nil, nil
      loop do
        sku = @test_store.get_random_item
        price = @test_store.get_item_price(sku)
        before = @test_store.get_sales_by_item(sku) || 0
        break if @test_store.buy_item(sku)
      end
      after = @test_store.get_sales_by_item(sku)
      assert_equal after, ( before + price )
    end
  end

  def test_cannot_buy_out_of_stock_item
    skip
    sku = get_random_item
    remaining = @test_store.get_stock(sku)
    remaining.times { @test_store.buy_item(sku) }
    assert_equal 0, @test_store.get_stock(sku)
    refute_equal true, @test_store.buy_item(sku)
  end

  def test_bestseller_provides_a_result
    skip
    b = @test_store.get_bestseller_list(1)
    assert_equal 1, b.length
  end

  # Sales over multiple days
  # Class StoreManager
  # Track sales over past n days (reduce randomness)
end
