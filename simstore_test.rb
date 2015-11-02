require 'minitest/autorun'
require_relative '../core/simstore.rb'

class RandomConfig
  attr_reader :config
  def initialize
    offset = rand(0..365) * 86400 # days
    @config = {
      :unique_items           => rand(10..201),
      :min_stock_per_item     => rand(1..21),
      :max_stock_per_item     => rand(22..37),
      :max_daily_transactions => rand(20..1001),
      :date                   => Time.now + offset
    }
  end
end

class SimStoreTest < Minitest::Test
  def setup
    # Setup a store object using random config
    @config = RandomConfig.new.config
    @config.each { |k, v| instance_variable_set("@#{k}", v) }
    @test_store = SimStore.new(@config)
    @test_store.populate_stock
    @test_tr_count = @test_store.run_business_day

    # Setup a store object using program's defaults
    @default_store = SimStore.new
    @default_store.populate_stock
    @test_df_count = @default_store.run_business_day

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

  def test_initial_stock_is_empty
    assert_equal 0, SimStore.new.stock.length
  end

  def test_items_have_required_form
    item = SimStore.new.make_item
    assert_instance_of Hash, item
    assert_equal 4, item.values.length
    assert_instance_of String, item[:title]
    assert_instance_of Fixnum, item[:price]
    assert_instance_of String, item[:sku]
    assert_instance_of String, item[:author]
  end

  def test_number_of_items
    assert_equal @unique_items, @test_store.stock.length
  end

  def test_stock_size_within_bounds
    c = RandomConfig.new.config
    store = SimStore.new(c)
    store.populate_stock
    size = store.stock.values.reduce(:+)
    min = c[:unique_items] * c[:min_stock_per_item]
    max = c[:unique_items] * c[:max_stock_per_item]
    assert(size.between?( min, max ))
  end

  def test_all_skus_are_unique
    skus = @test_store.item_list.collect { |item| item[:sku] }
    assert_equal skus.length, skus.uniq.length
  end

  def test_buying_an_item_decrements_stock
    if @test_store.stock.values.reduce(:+) == 0
      puts "No items in stock. Skipping this test."
    else
      sku, before = nil, nil
      loop do
        sku = @test_store.stock.keys.sample
        before = @test_store.stock[sku]
        break if @test_store.buy_item(sku)
      end
      after = @test_store.stock[sku]
      assert_equal after, ( before - 1 )
    end
  end

  def test_buying_an_item_updates_ledger
    if @test_store.stock.values.reduce(:+) == 0
      puts "No items in stock. Skipping this test."
    else
      sku, price, before = nil, nil, nil
      loop do
        sku = @test_store.stock.keys.sample
        price = @test_store.item_list.detect { |i| i[:sku] == sku }[:price]
        before = @test_store.get_sales_by_item(sku)
        break if @test_store.buy_item(sku)
      end
      after = @test_store.get_sales_by_item(sku)
      assert_equal after.to_i, ( before.to_i + price.to_i )
    end
  end

  def test_cannot_buy_out_of_stock_item
    sku = @test_store.stock.keys.sample
    remaining = @test_store.stock[sku]
    remaining.times { @test_store.buy_item(sku) }
    assert_equal 0, @test_store.stock[sku]
    refute_equal true, @test_store.buy_item(sku)
  end

  def test_ledger_records_all_transactions
    assert_equal @test_tr_count, @test_store.ledger.length
    assert_equal @test_df_count, @default_store.ledger.length
  end

  def test_ledger_records_correct_date
    assert_instance_of Time, @test_store.ledger.sample[0]
    assert(@test_store.ledger.sample[0].
      between?( @date.at_beginning_of_day, @date.at_end_of_day ))
    assert(@default_store.ledger.sample[0].
      between?( Time.now.at_beginning_of_day, Time.now.at_end_of_day ))
  end

  def test_header_count_matches_ledger
    assert_equal SimStore::T_HEADERS.length,
      @test_store.ledger.sample.length
  end

  def test_bestseller_provides_a_result
    b = @test_store.get_bestseller_list(1)
    assert_equal 1, b.length
  end

  def test_validate_top_bestseller
    b_list = @test_store.get_bestseller_list(1)
    counts = Hash.new(0)
    @test_store.ledger.reject { |row| row[4] == 0 }
    .each { |arr| counts[arr[1]] += 1 }
    top_sku = counts.max_by { |k, v| v }[0]
    assert_equal top_sku, b_list.max[1]
  end

  def test_report_success_html_substitutions
    assert_equal nil, @test_store.report_sales.match("BESTSELLERS")
  end

  def test_report_has_data
    assert_equal nil, @test_store.report_sales.match("<td></td>")
  end
end
