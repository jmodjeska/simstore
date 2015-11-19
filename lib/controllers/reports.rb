$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'models/queries'
require 'controllers/input_validator'

# Assemble parts for reports available to different store functions

module Reports
include Queries

  HEADERS = YAML.load_file('views/report_layouts.yml')
  REPORT_LOCATION = '../output/'

  def set_report_options( options = {} )
    start_date = get_transaction_date(:min) if
      ( options[:start_date].nil? || options[:start_date].length < 8 )
    end_date = get_transaction_date(:max) if
      ( options[:end_date].nil? || options[:start_date].length < 8 )

    @query_from   = validate_date_argument(start_date)
    @query_to     = validate_date_argument(end_date)
    @report_range = "#{@query_from.to_s[0..9]} to #{@query_from.to_s[0..9]}"
    @report_id    = ( options[:id].to_i == 0 ) ? nil : options[:id]
    @report_type  = options[:template]
  end

  def build_report
    unless defined? @report_type == "method"
      return "No such report: #{@report_type}"
    end
    eval( "prepare_#{@report_type}" )
  end

  def prepare_store_overview
    content = describe('Setting', 1)
      .reject { |s| s == "id" }
      .map do |k, v|
        [ k.capitalize.gsub("_", " ")
        .gsub("Date", "Current simulation date")
        .gsub("Db name", "DB location"), v ]
      end
    replace_html('overview', content)
  end

  def prepare_bestseller_report
    content = get_bestseller_list(@query_from, @query_to)
      .map { |item_hash| item_hash.values }
      .map.with_index { |list_row, i| list_row.unshift( i + 1 ) }
      .each { |list_row| list_row[-1] = ( "$%.2f" % list_row[-1] ) }
    replace_html('bestseller', content)
  end

  def prepare_sales_report
    content = get_sales_list(@query_from, @query_to)
      .each do |list_row|
        list_row[0] = ( list_row[0].to_s[0..18] ) # Format date
        list_row[4] = ( "$%.2f" % list_row[4] )   # Format price
        list_row[5] = ( "$%.2f" % list_row[5] )   # Format discount
        list_row[6] = ( "$%.2f" % list_row[6] )   # Format net sale
      end
    replace_html('sales', content)
  end

  def prepare_revenue_report
    content = get_total_revenues(@query_from, @query_to)
      .map do |row|
        [ row[0], ( "$%.2f" % row[1] ) ]
      end
    replace_html('revenue', content)
  end

  def prepare_replenish_report
    content = get_items_to_replenish
      .each do |list_row|
        list_row[5] = ( "$%.2f" % list_row[5] )   # Format price
      end
    replace_html('replenish', content)
  end

  def prepare_employee_list
    content = list_table("employee").map { |hash| hash.values }
    replace_html('employee', content)
  end

  def prepare_vendor_list
    content = list_table("vendor").map { |hash| hash.values }
    replace_html('vendor', content)
  end

  def prepare_promotion_list
    content = list_table("promotion").map { |hash| hash.values }
    replace_html('promotion', content)
  end

  def prepare_product_list
    content = list_table("product")
      .map { |hash| hash.values }
      .each do |list_row|
        list_row[4] = ( "$%.2f" % list_row[4] )
      end
    replace_html('product', content)
  end

  def html_table_header(arr)
    arr.map { |h| "<th><b>#{h}</b></th>" }.join
  end

  def html_table_rows(arr)
    arr.map do |tr|
      "<tr>" + tr.map do |td|
        "<td>#{td}</td>"
      end.join + "</tr>"
    end.join
  end

  def replace_html(headers, content)
    {
      :dates => @report_range,
      :headers => html_table_header(HEADERS["#{headers}_headers"]),
      :table => html_table_rows(content)
    }
  end
end
