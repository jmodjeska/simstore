require 'faker'
require 'active_support/all'
require 'nokogiri'

class SimStore
  attr_reader :stock, :item_list, :ledger

  DEFAULT_CONFIG = {
    :max_daily_transactions => 800,
    :min_stock_per_item     => 3,
    :max_stock_per_item     => 19,
    :unique_items           => 100
  }
  B_HEADERS = ["Position", "SKU", "Total Sold", "Title", "Author", "Revenue"]
  T_HEADERS = ["Date/Time", "SKU", "Title", "Author", "Sale Price", "Result"]
  RAW_HTML =
    # Nokogiri cleans this up on report generation :)
    '<title>SimStore Sales Report</title><link rel="stylesheet" ' +
    'href="http://yui.yahooapis.com/pure/0.6.0/pure-min.css">' +
    '<body style="margin: 20px"><h1>SimStore Sales Report for [-*DATE*-]</h1>' +
    '<h2>Bestseller List</h2><table class="pure-table pure-table-bordered">' +
    '<thead>[-*B_HEADERS*-]</thead><tbody>[-*BESTSELLERS*-]</tbody></table>' +
    '<h2>Sales Report</h2><table class="pure-table pure-table-bordered">' +
    '<thead>[-*T_HEADERS*-]</thead><tbody>[-*TRANSACTIONS*-]</tbody></table>'

  def initialize ( options = {} )
    options.reject! { |o, v| v == 0 || v.to_s.empty? }
    config = DEFAULT_CONFIG
    config[:date] = Time.now
    (config.merge!options).each { |k,v| instance_variable_set("@#{k}", v) }
    validate_input
    @skus = Array.new(@unique_items) { |i| i + 1 }
    @stock, @item_list, @ledger = {}, [], []
  end

  # Core public methods to run simulations

  def populate_stock
    @unique_items.times do
      item = make_item
      @stock[item[:sku]] = rand( @min_stock_per_item..@max_stock_per_item )
      @item_list << item
    end
  end

  def run_business_day
    sale_count = 0
    rand( 1..@max_daily_transactions ).times do |i|
      buy_item( @item_list.sample[:sku] )
      sale_count += 1
    end
    return sale_count
  end

  def get_bestseller_list(len = 10)
    # There must be an easier way ...
    ct, rv, l = Hash.new(0), Hash.new(0), @ledger.dup
    l.reject { |sale| sale[4] == 0 }
    .map { |rec| [rec[1], rec[4]] }
    .each { |arr| rv[arr[0]] += arr[1].to_i; ct[arr[0]] += 1 }

    ct.sort_by { |sku, ct| -ct }.first(len)
    .map.with_index { |item, i| [i + 1, item[0], item[1],
      inspect_item(item[0])[:title], inspect_item(item[0])[:author],
      sprintf('$%.2f', rv[item[0]]) ] }
  end

  def report_sales
    html = RAW_HTML
    html_replacements = {
      'DATE'         => @date.to_s[0..10],
      'B_HEADERS'    => html_table_header(B_HEADERS),
      'T_HEADERS'    => html_table_header(T_HEADERS),
      'BESTSELLERS'  => html_table_row(get_bestseller_list),
      'TRANSACTIONS' => html_table_row(@ledger)
    }
    html_replacements.each { |k, v| html.gsub!("[-*#{k}*-]", v) }
    Nokogiri::HTML(html).to_xhtml(indent: 3)
  end

  # Supporting methods (public so they're testable)

  def make_item
    item = {
      :sku    => sprintf( '%010d', @skus.pop ),
      :title  => make_random(:title),
      :price  => make_random(:price),
      :author => make_random(:author)
    }
  end

  def buy_item(sku)
    i = inspect_item(sku)
    row = [make_random(:time), sku, i[:title], i[:author]]
    if @stock[sku] > 0
      @stock[sku] -= 1
      @ledger << [row, "%.2f" % i[:price], "sold"].flatten
      return true
    else
      @ledger << [row, 0, "out of stock"].flatten
      return false
    end
  end

  def make_random(attribute)
    case attribute
    when :title
      Faker::Hacker.ingverb.capitalize + ' ' +
      Faker::Company.bs.split(' ')[1..-1].join(' ').titleize
    when :author then Faker::Name.name
    when :price then rand( 1..100 )
    when :time then @date.at_beginning_of_day + rand(0..3599)
    else raise NoMethodError.new("Can't make a random '#{attribute}'")
    end
  end

  def get_sales_by_item(sku)
    @ledger.select { |row| row[1] == sku }
      .map { |tr| tr[4].to_f }
      .reduce(:+) || 0
  end

  def inspect_item(sku)
    @item_list.detect { |item| item[:sku] == sku }
  end

  def html_table_header(arr)
    arr.map { |h| "<td>#{h}</td>" }.join
  end

  def html_table_row(arr)
    arr.map { |tr| "<tr>" + tr.map { |td|
      "<td>#{td}</td>" }.join + "</tr>" }.join
  end

  private
  def validate_input
    [@unique_items, @max_daily_transactions, @max_stock_per_item,
      @min_stock_per_item].each do |option|
      unless option.is_a?(Integer) && option > 0
        raise ArgumentError.new("invalid configuration value: #{option}")
      end
    end
    begin
      @date = ( @date.instance_of?(Time) ) ? @date : Time.parse(@date)
    rescue NoMethodError, TypeError
      raise ArgumentError.new("invalid date: #{@date}")
    end
    unless @max_stock_per_item > @min_stock_per_item
      raise ArgumentError.new("max stock must be greater than min stock")
    end
    if ( @unique_items * @max_stock_per_item ) < @max_daily_transactions
      warn "Warning: attempted transactions may exceed available stock."
    end
  end
end
