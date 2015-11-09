$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_support/all'
require 'active_record'
require 'models/models'
require 'yaml'

# Retrieve information about a store

module Queries
include Models

  SQL = YAML.load_file("../config/sql.yml")

  def db_exec(query, *params)
    begin
      sql = @db.connection.raw_connection.prepare(SQL[query])
      sql.bind_params( params ) if params
      return sql.execute.to_a
    rescue SQLite3::Exception => e
      raise StandardError.new("SimStore DB exception (SQLite3): #{e}")
    end
  end

  def count_items
    Product.count
  end

  def count_stock
    Product.sum( :in_stock )
  end

  def describe_item(id)
    Product.where( :id => id ).first.as_json
  end

  def describe_vendor(id)
    Vendor.where( :id => id ).first.as_json
  end

  def describe_employee(id)
    Employee.where( :id => id ).first.as_json
  end

  def get_stock_by_item(id)
    Product.where( :id => id ).first.as_json["in_stock"]
  end

  def get_price_by_item(id)
    Product.where( :id => id ).first.as_json["price"].to_f
  end

  def get_sales_by_item(id)
    db_exec('get_sales_by_item', id)
  end

  def get_revenue_by_item(id)
    [].tap do |sale_prices|
      get_sales_by_item(id).each do |sale|
        sale_prices << sale["price"]
      end
    end.reduce(:+)
  end

  def get_sales_by_employee(id)
    db_exec('get_sales_by_employee', id)
  end

  def get_sales_by_vendor(id)
    db_exec('get_sales_by_vendor', id)
  end

  def get_items_to_replenish
    db_exec('items_to_replenish')
  end

  # Reports by date range

  def parse_dates(from, to)
    from = Transaction.minimum( :date ) if from.nil?
    to = Transaction.maximum( :date ) if to.nil?
    from_date = Time.parse(from.to_s).at_beginning_of_day
    to_date = Time.parse(to.to_s).at_end_of_day
    return from_date.to_s, to_date.to_s
  end

  def get_total_revenues(from = nil, to = nil)
    from_date, to_date = parse_dates(from, to)
    Transaction
      .where( :date => from_date..to_date )
      .select( :date, :price )
  end

  def get_sales_list(from = nil, to = nil)
    from_date, to_date = parse_dates(from, to)
    db_exec('sales_list', [from_date, to_date]).as_json
  end

  def get_bestseller_list(from = nil, to = nil, len = 10)
    from_date, to_date = parse_dates(from, to)
    db_exec('get_bestseller_list', [from_date, to_date, len]).as_json
  end
end
