$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'models/queries'
require 'controllers/input_validator'
require 'yaml'
require 'htmlbeautifier'
require 'nokogiri'

# Assemble parts for reports available to different store functions

module Reports
include Queries

  TEMPLATES = YAML.load_file("../config/templates.yml")
  REPORT_LOCATION = '../output/'

  def set_report_options( options = {} )
    start_date    = get_transaction_date(:min) if options[:start_date].nil?
    end_date      = get_transaction_date(:max) if options[:end_date].nil?
    @query_from   = validate_date_argument(start_date)
    @query_to     = validate_date_argument(end_date)
    @report_range = "#{@query_from.to_s[0..9]} to #{@query_from.to_s[0..9]}"
    @report_id    = ( options[:id].to_i == 0 ) ? nil : options[:id]
    @report_type  = options[:template]
  end

  def build_report
    case @report_type
    when "sales_report"
      report = render_html('sales_report', prepare_sales_report)
      save_report(report, :sales)
    when "bestseller_report"
      report = render_html('bestseller_report', prepare_bestseller_report)
      save_report(report, :bestseller)
    else
      return "No such report: #{@report_type}."
    end
  end

  def prepare_bestseller_report
    content = get_bestseller_list(@query_from, @query_to)
      .map { |item_hash| item_hash.values }
      .map.with_index { |list_row, i| list_row.unshift( i + 1 ) }
      .each { |list_row| list_row[-1] = ( "$%.2f" % list_row[-1] ) }
    html_replacements = {
      'DATE' => @report_range,
      'HEADERS' => html_table_header(TEMPLATES['bestseller_headers']),
      'TABLE_CONTENT' => html_table_rows(content)
    }
  end

  def prepare_sales_report
    content = get_sales_list(@query_from, @query_to)
      .map { |row| row.values }
    html_replacements = {
      'DATE' => @report_range,
      'HEADERS' => html_table_header(TEMPLATES['sales_headers']),
      'TABLE_CONTENT' => html_table_rows(content)
    }
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

  def render_html(report_template, substitutions)
    template  = TEMPLATES['common_header']
    template += TEMPLATES[report_template]
    substitutions.each { |k, v| template.gsub!("[-*#{k}*-]", v) }
    HtmlBeautifier.beautify(Nokogiri::HTML(template).to_html)
  end

  def save_report(data, type)
    filename = "#{REPORT_LOCATION}simstore-" +
      "#{@store_name}_#{type}-report.html"
    File.write( filename, data )
    return File.exist?( filename ) ? true : false
  end
end
