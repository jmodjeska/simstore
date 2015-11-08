$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_record'
require 'models/models'
require 'controllers/item'
require 'controllers/contract'

module Simulations
include Models
include Item
include Contract

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

  def make_sale
    product  = Product.offset( rand(Product.count) ).first
    result   = product.in_stock.zero? ? "out-of-stock" : "sold"
    emp_id   = Employee.offset( rand(Employee.count) ).first.id
    datetime = ( @date.at_beginning_of_day + rand(0..3599) ).to_s

    product.decrement!(:in_stock) if Transaction.create(
      :employee_id => emp_id,
      :product_id  => product.id,
      :date        => datetime,
      :price       => product.price,
      :result      => result
    )
  end
end
