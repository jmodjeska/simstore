$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_record'
require 'models/models'

module Reports

  def sales_list(start_date, end_date)
  end

  def total_revenues(start_date, end_date)
  end

  def items_to_replenish(min_stock)
  end

  def get_sales_by_item(id)
  end

  def get_sales_by_employee(id)
  end

  def get_sales_by_vendor(id)

  def get_bestseller_list(len = 10)
    db_exec(SQL['bestsellers'],[len])
      .each.with_index { |r, i| r.unshift(i + 1) }.to_a
  end

end

__END__

bestseller_headers:
  - Position
  - SKU
  - Total Sold
  - Title
  - Author
  - Revenue

transaction_headers:
  - Date/Time
  - SKU
  - Title
  - Author
  - Sale Price
  - Result
