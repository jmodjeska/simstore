# Menu views for Store Manager

module Menus

  def fragments(selector)
    f = {
      :exit   => "\nPress any other key to exit\n\n",
      :main   => " - (m) Go back to the main menu",
      :back   => " - (s) Go back to the store menu",
      :store  => "Options for store: STORENAME\n" +
                 "Using database: DBNAME",
      :line   => "=========================================================\n",
      :output => "Output will be saved in HTML format in ../output/\n"
    }
    return f[selector]
  end

  def main_menu
    depth = 0
    banner = "\nWelcome to SimStore Manager!\n\n#{fragments(:line)}" +
      "MAIN MENU. Enter your desired option.\n#{fragments(:line)}"

    options = [
      ['Customize and setup a new store', 'configure_store_options'],
      ['Setup a new store with default options', 'run_sim']
      # ['Use an existing store', 'interface(existing_store_menu)']
    ]
    return depth, banner, options
  end

  def store_menu
    depth = 1
    banner = "#{fragments(:line)}#{fragments(:store)}\n#{fragments(:line)}"

    options = [
      ['Show details for your store', 'describe_store'],
      ['Generate a report for your store', "interface('report_menu')"],
      ['Simulate another day of sales', 'run_next_day']
    ]
    return depth, banner, options
  end

  # TODO - build logic to save store config
  # See simstore.rb @ 32
  # def existing_store_menu
  #   depth = 1
  #   banner = "\nHere are all the existing stores saved in ../data/"
  #   options = []
  #   Dir["../data/*.db"].each.with_index do |f, i|
  #     fname = File.basename(f, ".db")
  #     options << [i + 1, fname, "run_sim( :db_name => #{fname})"]
  #   end
  #   return depth, banner, options
  # end

  def report_menu
    depth = 2
    banner = "\nBusiness time! What report do you need?\n\n" +
      "#{fragments(:line)}#{fragments(:store)}\n#{fragments(:output)}" +
      fragments(:line)

    options = [
      ['Detailed Sales Report', "get_report('sales_report', 'dates')"],
      ['Bestseller Report', "get_report('bestseller_report', 'dates')"],
      ['Total Revenue Report', "get_report('revenue_report', 'dates')"],
      ['Low Inventory Report', "get_report('replenish_report')"],
      ['Employee List', "get_report('employee_list')"],
      ['Vendor List', "get_report('vendor_list')"],
      ['Product List', "get_report('product_list')"]
    ]
    return depth, banner, options
  end
end
