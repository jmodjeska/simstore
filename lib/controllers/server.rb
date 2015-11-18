$LOAD_PATH.unshift(File.dirname(__FILE__))
Dir.chdir("../")
require 'webrick'
require 'yaml'
require 'htmlbeautifier'
require 'nokogiri'
require 'simstore'
require 'controllers/routes'

# Simstore web server

class SimStoreServer < WEBrick::HTTPServlet::AbstractServlet
include Routes

  def do_GET(request, response)
    load_substitutions
    @store = nil
    status, content_type, body = render_html(route(request))
    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end

  def load_substitutions
    @substitutions = {
      'JUMBOTRON'       => '',
      'VERSION'         => SimStore::VERSION,
      'TIMESTAMP'       => Time.now.to_s,
      'DBNAME'          => 'None',
      'JAVASCRIPT'      => File.read('views/storebuilder.js'),
      'PROGRESS'        => '10',
      'MORE_JAVASCRIPT' => '',
      'STORENAME'       => '',
      'ERROR_MSG'       => 'An unknown error occurred :(',
      'ERROR_SHOW'      => 'none',
      'ERROR_PAD'       => '0'
    }
  end

  def render_html(params)
    http_response, page = params
    @substitutions.each { |k, v| page.gsub!( "[-*#{k}*-]", v ) }
    page.gsub!( /\[-\*(.+?)\*-\]/, "--" )
    page = HtmlBeautifier.beautify(Nokogiri::HTML(page).to_html)
    return http_response, 'text/html', page
  end
end

root = File.expand_path 'views'
puts "Root: #{root}"
server = WEBrick::HTTPServer.new(
  :Port => 8000,
  :DocumentRoot => root )
server.mount '/', SimStoreServer
trap("INT") { server.shutdown }
server.start
