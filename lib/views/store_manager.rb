$LOAD_PATH.unshift(File.dirname(__FILE__))
Dir.chdir("../")
require 'io/console'
require 'simstore'
require 'views/menus'

# Interact with the owner to accomplish critical tasks and run reports

class StoreManager
include Menus

  def initialize
    @store = nil
    show_menu('main_menu')
  end

  def show_menu(menu, message = nil)
    depth, banner, options = eval(menu)
    valid_options = []

    # Output the menu to the command line
    puts ""
    puts "\n#{message}\n\n" if message
    puts banner
    options.each.with_index do |opt, i|
      puts " - (#{i + 1}) #{opt[0]}"
      valid_options << i + 1
    end
    puts fragments(:main) if depth > 0
    puts fragments(:back) if depth > 1
    puts fragments(:exit)
    print "> "

    # Process user input
    option_selected = STDIN.getch
    puts "\n"
    if valid_options.include?( option_selected.to_i )
      eval(options[option_selected.to_i - 1][1])
    else
      case option_selected
      when "m"
        show_menu('main_menu')
      when "s"
        show_menu('store_menu')
      else
        exitmsg
        exit
      end
    end
  end

  def errormsg(step, e)
    puts "Oops! Something went wrong while trying to '#{step}': #{e}.\n\n"
    abort
  end

  def exitmsg
    puts "\nBye!\n\n"
  end

  def prompt(question)
    print " -=> #{question}: "
    return gets.chomp
  end

  def configure_store_options
    puts "Enter configuration options (or press enter to skip one):\n\n"
    options = {
      :unique_items           => prompt("Number of unique items (100)").to_i,
      :min_stock_per_item     => prompt("Min initial stock per item (3)").to_i,
      :max_stock_per_item     => prompt("Max initial stock per item (47)").to_i,
      :max_daily_transactions => prompt("Max transactions (800)").to_i,
      :max_price              => prompt("Max price for an item (100)").to_i,
      :vendors                => prompt("Number of vendors (5)").to_i,
      :employees              => prompt("Number of employees (6)").to_i,
      :date                   => prompt("Sales date (yyyy-mm-dd)"),
      :db_name                => prompt("Store name (text, no spaces)")
    }
    puts ""
    run_sim( options )
  end

  def get_report(report, *options_required)
    options = { :template => report }
    if options_required.include? 'dates'
      puts "Enter dates for report type '#{report}'."
      puts "Or press enter to use all available dates,\n\n"
      options[:start_date] = prompt("Start date (yyyy-mm-dd)")
      options[:end_date]   = prompt("End date (yyyy-mm-dd)")
    end
    @store.set_report_options( options )
    result = @store.build_report
    puts "\n"
    if result !~ /No such report/
      puts "Report generated! Check out: \n  #{result}\n\n"
    else
      errormsg('build_report', result)
    end
    puts "Press any key to return to the reports menu."
    STDIN.getch
    show_menu('report_menu')
  end

  def run_sim( options = {} )
    puts "Setting up your store ...\n\n"
    step_name = "setup_store"
    sim_steps = {
      :build_a_store    => Proc.new { @store = SimStore.new( options ) },
      :hire_employees   => Proc.new { @store.populate_employees },
      :contract_vendors => Proc.new { @store.populate_vendors },
      :stock_products   => Proc.new { @store.populate_products },
      :conduct_business => Proc.new { @store.populate_transactions }
    }
    begin
      sim_steps.each do |sim_step, sim_proc|
        step_name = sim_step.to_s
        print "- #{sprintf('%-22s ',
          (step_name.gsub("_", " ").capitalize + ' ... '))}"
        sim_proc.call ? puts("Done!") : errormsg(step_name, 'step failed')
      end
    rescue Exception => e
      errormsg(step_name, e)
    end
    show_menu('store_menu', 'This is great! You have a store. What now?')
  end

  def describe_store
    puts "\nHere's what we know about your store:\n\n"
    @store.instance_variables.each do |var|
      puts " - #{var}: #{@store.instance_variable_get(var)}"
    end
    puts "\n\nPress any key to return to the store menu.\n"
    STDIN.getch
    show_menu('store_menu')
  end

  def run_next_day
    @store.goto_next_day
    print "\nRunning another day of sales ... "
    print ( @store.populate_transactions ? "Done!" : "Failed :(" )
    puts ""
    show_menu('store_menu')
  end
end

# Runtime

print %x{clear}
interface = StoreManager.new
