require 'active_support/all'

module Validator
  def validate_integer_arguments
    [
      @unique_items,
      @max_daily_transactions,
      @max_stock_per_item,
      @min_stock_per_item,
      @employees,
      @vendors,
      @max_price
    ].each do |option|
      unless option.is_a?(Integer) && option > 0
        raise ArgumentError.new("invalid configuration value: #{option}")
      end
    end
  end

  def extract_db_name
    @db_name.match(/data\/(.*?)\./)[1]
  end

  def assemble_db_name(name)
    "../data/#{name.to_s}.db"
  end

  def validate_date_argument(date)
    begin
      date = ( date.instance_of?(Time) ) ? date : Time.parse(date)
    rescue NoMethodError, TypeError
      raise ArgumentError.new("invalid date: #{date}")
    end
    return date
  end

  def validate_range_arguments
    unless @max_stock_per_item > @min_stock_per_item
      raise ArgumentError.new("max stock must be greater than min stock")
    end
  end

  def warn_on_insufficient_stock
    if ( @unique_items * @max_stock_per_item ) < @max_daily_transactions
      warn "Warning: attempted transactions may exceed available stock."
    end
  end
end
