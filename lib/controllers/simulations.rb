$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_record'
require 'models/models'
require 'controllers/item'
require 'controllers/contract'

# Simulate store actions

module Simulations
include Models
include Item
include Contract

  def populate_everything
    populate_vendors
    populate_employees
    populate_products
    populate_transactions
  end

  def populate_vendors
    @vendors.times { Vendor.create( setup_vendor ) }
  end

  def populate_employees
    @employees.times { Employee.create( setup_employee ) }
  end

  def populate_products
    @unique_items.times { Product.create( setup_item ) }
  end

  def populate_transactions
    rand( 1..@max_daily_transactions ).times { make_sale }
  end

  def decrement_stock(product)
    if product.in_stock.zero?
      return "out-of-stock", 0
    else
      product.decrement!(:in_stock)
      return "sold", product.price
    end
  end

  def make_sale(id = false)
    product =
      if id
        Product.where( :id => id ).first
      else
        Product.offset( rand(Product.count) ).first
      end
    result, price = decrement_stock(product)
    emp_id = Employee.offset( rand(Employee.count) ).first.id
    datetime = ( @date.at_beginning_of_day + rand(0..86399) )
    sale = Transaction.create(
      :employee_id => emp_id,
      :product_id  => product.id,
      :date        => datetime,
      :price       => price,
      :result      => result
    )
    return ( result == "sold" && sale ) ? true : false
  end
end
