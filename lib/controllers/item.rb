$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'faker'

module Item
  def vendor_id
    rand( 1..@vendors )
  end

  def title
    Faker::Hacker.ingverb.capitalize + ' ' +
    Faker::Company.bs.split(' ')[1..-1].join(' ').titleize
  end

  def author
    Faker::Name.name
  end

  def price
    rand( 1..@max_price )
  end

  def initial_stock
    rand( @min_stock_per_item..@max_stock_per_item)
  end

  def min_stock
    rand ( 1..@min_stock_per_item )
  end

  def setup_item
    {
      :vendor_id => vendor_id,
      :title     => title,
      :author    => author,
      :price     => price,
      :in_stock  => initial_stock
    }
  end
end
