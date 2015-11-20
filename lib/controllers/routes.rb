$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'views/ui_assembler'

# Routes for request paths for SimStore webserver

module Routes
include UIAssembler

  TEMPLATES = YAML.load_file('views/templates.yml')

  def not_found
    http_response = 404
    page_content = TEMPLATES['common_header']
    @substitutions['CONTAINER'] = 'container'
    page_content += TEMPLATES['not_found']
    page_content += TEMPLATES['common_footer']
    return [http_response, page_content]
  end

  def error_message(err)
    @substitutions['ERROR_MSG'] = err
    @substitutions['ERROR_SHOW'] = 'block'
    @substitutions['ERROR_PAD'] = '300'
    @substitutions['REPORT_TITLE'] = 'Error'
    return TEMPLATES['general_error']
  end

  def route(request)
    http_response, page_content = 200, ''

    # Modal Store Setup
    if request.path.include? "modal"
      begin
        case request.path
        when "/modal_new_store"
          @store = SimStore.new
          page_content = @store.extract_db_name
        when "/modal_store_do_next"
          if request.query["db"]
            @store = SimStore.new( :db_name => request.query["db"] )
            page_content = @store.continue_unfinished_simulation.to_s
          else
            return not_found
          end
        when "/modal_run_sales"
          @store = SimStore.new( :db_name => request.query["db"] )
          @store.goto_next_day
          page_content = "OK" if @store.populate_transactions
        when "/modal_add_stock"
          @store = SimStore.new( :db_name => request.query["db"] )
          page_content = "OK" if @store.add_stock
        when "/modal_apply_promotions"
          @store = SimStore.new( :db_name => request.query["db"] )
          page_content = "OK" if @store.assign_promotions_to_products
        else
          return not_found
        end
      rescue Exception => e
        page_content = "Error: #{e}"
      end
      return [http_response, page_content]

    # Pages
    else
      page_content = TEMPLATES['common_header']
      case request.path
      when "/"
        @substitutions['CONTAINER'] = 'container'
        @substitutions['JUMBOTRON'] = TEMPLATES['jumbotron']
        @substitutions['MORE_JAVASCRIPT'] = TEMPLATES['clear_cookies']
      when "/main"
        @substitutions['CONTAINER'] = 'container'
        page_content += TEMPLATES['main_menu']
      when "/manage_store"
        if request.query["db"]
          @store = SimStore.new( :db_name => request.query["db"] )
          @substitutions['CONTAINER'] = 'container-fluid'
          begin
            page_content += side_nav_items
            page_content += TEMPLATES['dashboard_header']
            @substitutions['CONTAINER'] = 'container-fluid'
            @substitutions['MORE_JAVASCRIPT'] = TEMPLATES['hide_kill_db']
            @substitutions['STORENAME'] = @store.extract_db_name
            if request.query["list"]
              err, assembly = get_list( request.query["list"] )
              page_content += err ? error_message(err) : assembly
            elsif request.query["report"]
              err, assembly = get_report( request.query["report"],
                request.query["start_date"], request.query["end_date"] )
              page_content += err ? error_message(err) : assembly
            elsif request.query["sim"]
              err, sim_page = do_sim( request.query["sim"] )
              page_content += err ? error_message(err) : sim_page
            elsif request.query["detail"] && request.query["id"]
              page_content += show_detail( request.query["detail"],
                request.query["id"] )
            else
              err, assembly = get_list( 'store_overview' )
              page_content += err ? error_message(err) : assembly
            end
          rescue Exception => e
            page_content += error_message("Problem with " +
              "#{request.query["db"]}: #{e}<br><br>Backtrace: #{e.backtrace}")
          end
          page_content += TEMPLATES['dashboard_footer']
        else
          return not_found
        end
      else
        return not_found
      end
      page_content += TEMPLATES['common_footer']
      return [http_response, page_content]
    end
  end
end
