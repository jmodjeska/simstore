
# Complex UI rules and assemblers for SimStore webserver

module UIAssembler

  TEMPLATES = YAML.load_file('views/templates.yml')
  SIDE_NAV = [
    list_options = [
      ['Store Information', 'list'],
      ['Overview', 'store_overview', 'none'],
      ['Employees', 'employee_list', 'none'],
      ['Vendors', 'vendor_list', 'none'],
      ['Products', 'product_list', 'none'],
      ['Promotions', 'promotion_list', 'activate']
    ],
    report_options = [
      ['Reports', 'report'],
      ['Sales Report', 'sales_report', 'start_date', 'end_date'],
      ['Bestseller Report', 'bestseller_report', 'start_date', 'end_date'],
      ['Revenue Report', 'revenue_report', 'start_date', 'end_date'],
      ['Replenish Report', 'replenish_report']
    ],
    simulation_options = [
      ['Actions', 'sim'],
      ['Run More Sales', 'run_sales'],
      ['Add More Stock', 'add_more_stock'],
      ['Apply Promotions', 'apply_promotions']
    ]
  ]

  def side_nav_items
    side_nav = ""
    SIDE_NAV.each do |ul|
      side_nav += '<ul class="nav nav-sidebar">'
      side_nav += "<li><p class=\"nav-section\">#{ul[0][0]}</p></li>"
      ul.each.with_index do |li, i|
        next if i == 0
        side_nav += "<li><a href=\"?#{ul[0][1]}=#{li[1]}&db=" +
          "#{@store.extract_db_name}\">#{li[0]}</a></li>"
      end
      side_nav += '</ul>'
    end
    return TEMPLATES['dashboard_sidebar'].gsub("[-*SIDE_NAV*-]", side_nav)
  end

  def get_title(search_array_index, item)
    SIDE_NAV[search_array_index][SIDE_NAV[search_array_index].index
      .each { |arr| arr.index(item) }][0]
  end

  def get_list(list)
    @store.set_report_options( :template => list )
    finalize_assembly(0, list)
  end

  def get_report(report, start_date, end_date)
    options = {
      :template => report,
      :start_date => start_date,
      :end_date => end_date
    }
    @store.set_report_options( options )
    finalize_assembly(1, report)
  end

  def do_sim(sim)
    content = TEMPLATES['dashboard_sim_header']
    case sim
    when 'run_sales'
      content += TEMPLATES['dashboard_run_sales']
    when 'add_more_stock'
      content += TEMPLATES['dashboard_add_stock']
    when 'apply_promotions'
      content += TEMPLATES['dashboard_apply_promotions']
    else
      raise StandardError.new("#{sim}: I don't know how to do that.")
    end
    content += TEMPLATES['dashboard_sim_footer']
    return [false, content]
  end

  def show_detail(type, id)
    options = {
      :template => 'show_detail',
      :describe => type,
      :id => id
    }
    @store.set_report_options( options )
    content = @store.build_report
    return [false, TEMPLATES['dashboard_detail']
      .gsub( '[-*DETAIL_ICON*-]', ICON_TYPES[type] )
      .gsub( '[-*DETAIL_NAME*-]', type.capitalize )
      .gsub( '[-*DETAILS*-]', content )]
  end

  def finalize_assembly(request_array, request_type)
    content = @store.build_report
    if content !~ /No such report/
      return [false, TEMPLATES['dashboard_main']
      .gsub( '[-*REPORT_TITLE*-]', get_title(request_array, request_type) )
      .gsub( '[-*HEADERS*-]', content[:headers] )
      .gsub( '[-*TABLE_CONTENT*-]', content[:table] )]
    else
      raise StandardError.new("#{request_type}: #{content}")
    end
  end
end
