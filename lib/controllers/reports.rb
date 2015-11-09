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
    if options[:from_date].nil?
      @query_from = nil
      @report_from = "All Time"
    else
      @query_from = validate_date_argument(options[:from_date])
      @report_from = "#{@query_from.to_s[0..9]} to "
    end

    if options[:to_date].nil?
      @query_to, @report_to = nil, nil
    else
      @query_from = validate_date_argument(options[:from_date])
      @report_from = @query_from.to_s[0..9]
    end

    @report_id = ( options[:id].to_i == 0 ) ? nil : options[:id]
    @report_template = options[:template]
  end

  def build_report
    case @report_template
    when "sales_report"
      report = render_html('sales_report', prepare_sales_report)
      save_report(report, :sales)
    when "bestseller_report"
      report = render_html('bestseller_report', prepare_bestseller_report)
      save_report(report, :bestseller)
    else
      return "No such report: #{@report_template}."
    end
  end

  def prepare_bestseller_report
    content = get_bestseller_list(@query_from, @query_to)
      .map { |row| row.values }
    html_replacements = {
      'DATE' => "#{@report_from} #{@report_to}",
      'HEADERS' => html_table_header(TEMPLATES['bestseller_headers']),
      'TABLE_CONTENT' => html_table_rows(content)
    }
  end

  def prepare_sales_report
    content = get_sales_list(@query_from, @query_to)
      .map { |row| row.values }
    html_replacements = {
      'DATE' => "#{@report_from} #{@report_to}",
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
    template  = TEMPLATES[common_header]
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
