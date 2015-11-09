require 'minitest/autorun'
require_relative '../lib/simstore.rb'
require_relative 'randomconfig.rb'

class SimStoreTest < Minitest::Test

  def setup
    @config = RandomConfig.new.config
    @config.each { |k, v| instance_variable_set("@#{k}", v) }
    @test_store = SimStore.new(@config)
    @test_store.populate_everything
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
    product_id = rand( 1..@test_store.count_items )
    item_form = @test_store.describe_item(product_id)
    assert_equal Fixnum, item_form["vendor_id"].class
    assert_equal String, item_form["title"].class
    assert_equal String, item_form["author"].class
  end

  def test_number_of_items
    assert_equal @unique_items, @test_store.count_items
  end

  def test_stock_size_within_bounds
    c = RandomConfig.new.config
    store = SimStore.new(c)
    store.populate_everything
    size = store.count_stock
    min = c[:unique_items] * c[:min_stock_per_item]
    max = c[:unique_items] * c[:max_stock_per_item]
    assert(size.between?( min, max ))
  end

  def test_buying_an_item_decrements_stock
    if @test_store.count_stock == 0
      puts "No items in stock. Skipping this test."
    else
      product_id, before = nil, nil
      loop do
        product_id = rand( 1..@test_store.count_items )
        before = @test_store.get_stock_by_item(product_id)
        break if @test_store.make_sale(product_id)
      end
      after = @test_store.get_stock_by_item(product_id)
      assert_equal after, ( before - 1 )
    end
  end

  def test_buying_an_item_updates_ledger
    if @test_store.count_stock == 0
      puts "No items in stock. Skipping this test."
    else
      product_id , price, before = nil, nil, nil
      loop do
        product_id = rand( 1..@test_store.count_items )
        price = @test_store.get_price_by_item(product_id)
        before = @test_store.get_revenue_by_item(product_id) || 0
        break if @test_store.make_sale(product_id)
      end
      after = @test_store.get_revenue_by_item(product_id)
      assert_equal after, ( before + price )
    end
  end

  def test_cannot_buy_out_of_stock_item
    product_id = rand( 1..@test_store.count_items )
    remaining = @test_store.get_stock_by_item(product_id)
    remaining.times { @test_store.make_sale(product_id) }
    assert_equal 0, @test_store.get_stock_by_item(product_id)
    refute_equal true, @test_store.make_sale(product_id)
  end

  def test_bestseller_provides_a_result
    b = @test_store.get_bestseller_list(nil, nil, 1)
    assert_equal 1, b.length
  end
end
