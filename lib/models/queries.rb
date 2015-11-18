$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_support/all'
require 'active_record'
require 'models/models'
require 'yaml'

# Retrieve information about a store

module Queries
include Models

  SQL = YAML.load_file('models/sql.yml')

  def db_exec(query, *params)
    begin
      sql = @db.connection.raw_connection.prepare(SQL[query])
      sql.bind_params( params ) if params
      return sql.execute.to_a
    rescue SQLite3::Exception => e
      raise StandardError.new("SimStore DB exception (SQLite3): #{e}")
    end
  end

  def check_setup_completion
    Setting.first
      .as_json
      .find_all { |k, v| v.nil? || v.to_s == "0" }
  end

  def check_sim_completion
    [Vendor, Employee, Product, Promotion, Transaction].each do |check|
      return check.table_name if check.first.as_json.nil?
    end
    return "OK"
  end

  def describe(model, id)
    eval( "#{model.capitalize}" )
      .where( :id => id )
      .first.as_json
  end

  def list_table(table)
    eval( "#{table.capitalize}" ).all.as_json
  end

  def count_items
    Product.count
  end

  def count_stock
    Product.sum( :in_stock )
  end

  def get_stock_by_item(id)
    Product
      .where( :id => id )
      .first.as_json["in_stock"]
  end

  def get_price_by_item(id)
    Product
      .where( :id => id )
      .first.as_json["price"]
  end

  def get_revenue_by_item(id)
    Transaction
      .where( :product_id => id )
      .map { |tr| tr.net_sale }
      .reduce(:+)
  end

  def get_sales_by_employee(id)
    Transaction
      .where( :employee_id => id ).as_json
      .each { |hash| hash["price"] = hash["price"].to_s }
  end

  def get_sales_by_vendor(id)
    Transaction.joins( :product )
      .where( "products.vendor_id = ?", id ).as_json
      .each { |hash| hash["price"] = hash["price"].to_s }
  end

  def get_items_to_replenish
    Product.where( "in_stock < min_stock" ).map do |pr|
      [ pr.id, pr.vendor_id, pr.vendor.name, pr.title,
      pr.author, pr.price.to_s, pr.in_stock, pr.min_stock ]
    end
  end

  def check_active_promotion(product_id)
    Product.find_by( id: product_id ).promotion_id.to_i
  end

  # Queries by date range

  def get_transaction_date(bound)
    case bound
    when :min then return Transaction.minimum( :date )
    when :max then return Transaction.maximum( :date )
    end
  end

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
      .group( :date )
      .sum( :net_sale )
      .map { |k, v| [ k.to_s[0..9], v ] }
      .group_by(&:first)
      .each_value { |arr| arr.each { |row| row.shift } }
      .map { |k, v| [ k, v.flatten.reduce(:+) ] }
  end

  def get_sales_list(from = nil, to = nil)
    from_date, to_date = parse_dates(from, to)
    Transaction.where( :date => from_date..to_date ).map do |sale|
      [ sale.date, sale.product_id, sale.qty, sale.product.title,
      sale.price, sale.discount, sale.net_sale.to_s, sale.employee.name,
      sale.result, sale.promotion_id ]
    end
  end

  def get_bestseller_list(from = nil, to = nil, len = 10)
    from_date, to_date = parse_dates(from, to)
    db_exec('get_bestseller_list', [from_date, to_date, len]).as_json
  end
end
