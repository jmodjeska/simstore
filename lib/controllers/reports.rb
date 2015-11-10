$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'models/queries'
require 'controllers/input_validator'
require 'yaml'
require 'htmlbeautifier'
require 'nokogiri'

# Assemble parts for reports available to different store functions

module Reports
include Queries

  TEMPLATES = YAML.load_file('views/templates.yml')
  REPORT_LOCATION = '../output/'

  def set_report_options( options = {} )
    start_date    = get_transaction_date(:min) if
      ( options[:start_date].nil? || options[:start_date].length < 8 )
    end_date      = get_transaction_date(:max) if
      ( options[:end_date].nil? || options[:start_date].length < 8 )
    @query_from   = validate_date_argument(start_date)
    @query_to     = validate_date_argument(end_date)
    @report_range = "#{@query_from.to_s[0..9]} to #{@query_from.to_s[0..9]}"
    @report_id    = ( options[:id].to_i == 0 ) ? nil : options[:id]
    @report_type  = options[:template]
  end

  def build_report
    savable = true
    case @report_type
    when 'sales_report'
      report = render_html('sales_report', prepare_sales_report)
    when 'bestseller_report'
      report = render_html('bestseller_report', prepare_bestseller_report)
    when 'revenue_report'
      report = render_html('revenue_report', prepare_revenue_report)
    when 'replenish_report', 'low_inventory_report'
      report = render_html('replenish_report', prepare_replenish_report)
    when 'employee_list'
      report = render_html('employee_list', prepare_employee_list)
    when 'vendor_list'
      report = render_html('vendor_list', prepare_vendor_list)
    when 'product_list'
      report = render_html('product_list', prepare_product_list)
    else
      return "No such report: #{@report_type}."
      savable = false
    end
    save_report(report, @report_type) if savable
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
      .map { |item_hash| item_hash.values }
      .each do |list_row|
        list_row[0] = ( list_row[0].to_s[0..18] ) # Format date
        list_row[4] = ( "$%.2f" % list_row[4] )   # Format price
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
      .map { |item_hash| item_hash.values }
    replace_html('replenish', content)
  end

  def prepare_employee_list
    content = list_employees.map { |hash| hash.values }
    replace_html('employee', content)
  end

  def prepare_vendor_list
    content = list_vendors.map { |hash| hash.values }
    replace_html('vendor', content)
  end

  def prepare_product_list
    content = list_products
      .map { |hash| hash.values }
      .each do |list_row|
        list_row[4] = ( "$%.2f" % list_row[4] )
      end
    replace_html('product', content)
  end

  def html_table_header(arr)
    arr.map { |h| "<td>#{h}</td>" }.join
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
      'DATE' => @report_range,
      'HEADERS' => html_table_header(TEMPLATES["#{headers}_headers"]),
      'TABLE_CONTENT' => html_table_rows(content)
    }
  end

  def render_html(report_template, substitutions)
    template  = TEMPLATES['common_header']
    template += TEMPLATES[report_template]
    template += TEMPLATES['common_table']
    substitutions.each { |k, v| template.gsub!("[-*#{k}*-]", v) }
    HtmlBeautifier.beautify(Nokogiri::HTML(template).to_html)
  end

  def save_report(data, type)
    filename = "#{REPORT_LOCATION}simstore-" +
      "#{@store_name}_#{type}.html"
    File.write( filename, data )
    return File.exist?( filename ) ? filename : false
  end
end
