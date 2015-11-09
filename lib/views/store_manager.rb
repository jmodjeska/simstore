$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'io/console'
require 'simstore'

# Interact with the owner to accomplish critical tasks and run reports

def welcome_msg
  puts "\nLet's setup a new store!"
  puts " - Press 's' to proceed with setup"
  puts " - Press 'd' to proceed with default options"
  puts " - Press any other key to exit \n\n"
end

def prompt(question)
  print " -=> #{question}: "
  return gets.chomp
end

def configure_store_options
  puts "Enter configuration options (or press enter to skip one):\n\n"
  options = {
    :unique_items           => prompt("Number of unique items").to_i,
    :min_stock_per_item     => prompt("Minimum initial stock per item").to_i,
    :max_stock_per_item     => prompt("Maximum initial stock per item").to_i,
    :max_daily_transactions => prompt("Maximum number of transactions").to_i,
    :max_price              => prompt("Max price for an item").to_i
    :vendors                => prompt("Number of vendors").to_i
    :employees              => prompt("Number of employees").to_i
    :date                   => prompt("Sales date (yyyy-mm-dd)")
    :db_name                => prompt("Store (database) name")
  }
  puts ''
  return options
end

def configure_report_options
  # What report do you want? (list with numbers)
  # Save report to "example_output" dir, at least for now
  # Run another report?
end

def run_simulation(options = {})
  print "Running simulation ..."
  begin
    store = SimStore.new(options)
    store.populate_everything
  rescue ArgumentError => e
    puts "\nOops, something went wrong: #{e}\n"
    abort
  end
  print "Done!\n"
  # Run another day's sales?
end

# Runtime
store = nil
welcome_msg

case STDIN.getch
when 's' # Setup
  bestsellers, report = run_simulation(configure_store_options)
when 'd' # Defaults
  bestsellers, report = run_simulation
else
  exit
end

# Prompt for reporting options
