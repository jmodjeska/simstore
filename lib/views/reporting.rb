require 'htmlbeautifier'
require 'nokogiri'

  def report_sales
    html = CONFIG['raw_html']
    html_replacements = {
      'DATE'         => @date.to_s[0..10],
      'B_HEADERS'    => html_table_header(CONFIG['bestseller_headers']),
      'T_HEADERS'    => html_table_header(CONFIG['transaction_headers']),
      'TRANSACTIONS' => html_table_row(db_exec(SQL['get_ledger'])),
      'BESTSELLERS'  => html_table_row(get_bestseller_list)
    }
    html_replacements.each { |k, v| html.gsub!("[-*#{k}*-]", v) }
    HtmlBeautifier.beautify(Nokogiri::HTML(html).to_html)
  end



  # HTML parts

  def html_table_header(arr)
    arr.map { |h| "<td>#{h}</td>" }.join
  end

  def html_table_row(arr)
    arr.map { |tr| "<tr>" + tr.map { |td|
      "<td>#{td}</td>" }.join + "</tr>" }.join
  end


__END__

# SimStore HTML templates

raw_html: >
  <title>SimStore Sales Report</title>
  <link rel="stylesheet" href="http://yui.yahooapis.com/pure/0.6.0/pure-min.css">
  <body style="margin: 20px;"><h1>SimStore Sales Report for [-*DATE*-]</h1>
  <h2>Bestseller List</h2><table class="pure-table pure-table-bordered">
  <thead>[-*B_HEADERS*-]</thead><tbody>[-*BESTSELLERS*-]</tbody></table>
  <h2>Sales Report</h2><table class="pure-table pure-table-bordered">
  <thead>[-*T_HEADERS*-]</thead><tbody>[-*TRANSACTIONS*-]</tbody></table>
