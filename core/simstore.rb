require 'active_support/all'
require 'faker'
require 'nokogiri'
require 'yaml'
require 'sqlite3'
require 'htmlbeautifier'

class SimStore
  attr_accessor :db
  CONFIG = YAML.load_file("../config/config.yml")
  SQL = YAML.load_file("../config/sql.yml")

  def initialize ( options = {} )
    options.reject! { |o, v| v == 0 || v.to_s.empty? }
    defaults = CONFIG['defaults']
    defaults[:date] = Time.now
    (defaults.merge!options).each { |k,v| instance_variable_set("@#{k}", v) }
    validate_input
    @skus = Array.new(@unique_items) { |i| sprintf( '%010d', i + 1 ) }
    @db, @db_name = db_exec(:setup)
  end

  # Core public methods to run simulations

  def populate_stock
    SQL.select { |k, v| db_exec(v) if k[/^setup_table/] }
    @unique_items.times do
      item = make_item
      db_exec(SQL['add_to_books'], item)
      db_exec(SQL['add_to_stock'], [item[0], random(:stock)])
    end
  end

  def run_business_day
    sale_count = 0
    rand( 1..@max_daily_transactions ).times { |i|
      buy_item( db_exec(SQL['random_book']).first[1] ) }
  end

  def get_bestseller_list(len = 10)
    db_exec(SQL['bestsellers'],[len])
      .each.with_index { |r, i| r.unshift(i + 1) }.to_a
  end

  def report_sales
    html = CONFIG['raw_html']
    html_replacements = {
      'DATE'         => @date.to_s[0..10],
      'B_HEADERS'    => html_table_header(CONFIG['bestseller_headers']),
      'T_HEADERS'    => html_table_header(CONFIG['transaction_headers']),
      'TRANSACTIONS' => html_table_row(db_exec(SQL['get_ledger'])),
      'BESTSELLERS'  => html_table_row(get_bestseller_list)
    }
    html_replacements.each { |k, v| html.gsub!("[-*#{k}*-]", v) }
    HtmlBeautifier.beautify(Nokogiri::HTML(html).to_html)
  end

  # DB access

  def db_exec(cmd_string, *params)
    begin
      if cmd_string == :setup
        name = "simstore_#{random(:db)}.db"
        return (SQLite3::Database.new ":memory:"), name
      else
        cmd = @db.prepare cmd_string
        cmd.bind_params( params ) if params
        return cmd.execute.to_a
      end
    rescue SQLite3::Exception => e
      raise StandardError.new("SimStore DB exception: #{e}")
    end
  end

  # Item interaction

  def make_item
    [@skus.pop, random(:title), random(:author), random(:price)]
  end

  def buy_item(sku)
    price, stock = db_exec(SQL['an_item'], sku)[0]
    row = [random(:time), sku]
    if stock > 0
      db_exec(SQL['add_to_ledger'], [row, price, "sold"].flatten)
      db_exec(SQL['update_stock'], sku)
      return true
    else
      db_exec(SQL['add_to_ledger'], [row, 0, "out of stock"].flatten)
      return false
    end
  end

  def get_sales_by_item(sku)
    db_exec(SQL['ledger_item'], sku)[0][0]
  end

  # HTML parts

  def html_table_header(arr)
    arr.map { |h| "<td>#{h}</td>" }.join
  end

  def html_table_row(arr)
    arr.map { |tr| "<tr>" + tr.map { |td|
      "<td>#{td}</td>" }.join + "</tr>" }.join
  end

  # Other stuff

  def random(attribute)
    case attribute
    when :title
      Faker::Hacker.ingverb.capitalize + ' ' +
      Faker::Company.bs.split(' ')[1..-1].join(' ').titleize
    when :author then Faker::Name.name
    when :price then rand( 1..100 )
    when :time then (@date.at_beginning_of_day + rand(0..3599)).to_s
    when :stock then rand( @min_stock_per_item..@max_stock_per_item )
    when :db then ('a'..'z').to_a.shuffle[0,32].join
    else raise NoMethodError.new("Can't make a random '#{attribute}'")
    end
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
    return true
  end
end
