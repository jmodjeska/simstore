$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_record'
require 'models/models'
require 'models/queries'
require 'controllers/item'
require 'controllers/contract'

# Simulate store actions

module Simulations
include Models
include Item
include Contract

  CONFIG = YAML::load_file("../config/config.yml")
  PROMOTIONS = CONFIG['promotions']

  def populate_everything
    populate_vendors
    populate_employees
    populate_products
    populate_promotions
    populate_transactions
  end

  def continue_unfinished_simulation
    return "OK" if check_sim_completion == "OK"
    return eval( "populate_#{check_sim_completion}" )
  end

  def populate_vendors
    @vendors.times { Vendor.create( setup_vendor ) }
    return ( Vendor.take( @vendors ).count == @vendors )
  end

  def populate_employees
    @employees.times { Employee.create( setup_employee ) }
    return ( Employee.take( @employees ).count == @employees )
  end

  def populate_products
    @unique_items.times { Product.create( setup_item ) }
    return ( Product.take( @unique_items ).count == @unique_items )
  end

  def add_stock
    id = 1
    @unique_items.times do
      amount = rand( 1..@max_stock_per_item )
        Product.find_by( :id => id ).increment!( :in_stock, by = amount )
      id += 1
    end
    return ( Product.take( @unique_items ).count == @unique_items )
  end

  def populate_transactions
    random_sales = rand( 1..@max_daily_transactions )
    random_sales.times { make_sale }
    return ( Transaction.take( random_sales ).count == random_sales )
  end

  def populate_promotions
    PROMOTIONS.each do |name, logic|
      Promotion.create( { :name => name, :logic => logic } )
    end
    return true
  end

  def assign_promotions_to_products
    # Hard-coded to apply promos to first 10% of products
    # for demonstration purposes
    id = 1
    ( @unique_items / 10 ).times do
      promo_id = rand(1..PROMOTIONS.length )
      Product.find_by( :id => id ).update( promotion_id: promo_id )
      id += 1
    end
  end

  def activate_promotion(product_id, promo_id)
    Product.find_by( id: product_id ).update( promotion_id: promo_id )
  end

  def apply_promotions(product)
    price, discount, promo_id = product.price, 0, product.promotion_id
    if promo_id.to_i > 0
      discount = eval( describe( "promotion", promo_id )["logic"] )
    end
    return discount, promo_id
  end

  def goto_next_day
    @date = @date.at_beginning_of_day + 24.hours
    save_config
  end

  def decrement_stock(product, requested)
    currently_available = product.in_stock
    case
    when currently_available == 0
      return 'out-of-stock', 0, 0
    when currently_available < requested
      product.decrement!( :in_stock, by = currently_available )
      return 'sold-partial', currently_available, product.price
    else
      product.decrement!( :in_stock, by = requested )
      return 'sold', requested, product.price
    end
  end

  def make_sale(pid = false)
    product =
      if pid
        Product.where( :id => id ).first
      else
        Product.offset( rand(Product.count) ).first
      end
    requested = rand( 1..@max_unique_per_sale )
    result, qty, price = decrement_stock(product, requested)
    discount, promo_id = apply_promotions(product)

    sale = Transaction.create(
      :employee_id  => Employee.offset( rand(Employee.count) ).first.id,
      :product_id   => product.id,
      :date         => ( @date.at_beginning_of_day + rand(0..86399) ),
      :price        => ( price * qty ),
      :discount     => discount,
      :promotion_id => promo_id,
      :net_sale     => ( price * qty ) - discount,
      :qty          => qty,
      :result       => result
    )
    return qty
  end
end
