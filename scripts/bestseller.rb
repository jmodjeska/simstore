# Jeremy Modjeska
# Ruby 110A - Assignment 4
# 31 October 2015
#
# Show 10 bestselling products over 24 hrs, based on sales until midnight PST.
# Indicate number of items sold, item prices, total revenue; in order of rank.
#
# Solution: bestseller.rb

require 'io/console'
require_relative '../core/simstore.rb'

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
    :date                   => prompt("Sales date (yyyy-mm-dd)")
  }
  puts ''
  return options
end

def run_simulation(options = {})
  print "Running simulation ..."
  begin
    store = SimStore.new(options)
    store.populate_stock
    store.run_business_day
    bestsellers = store.get_bestseller_list
    report = store.report_sales
  rescue ArgumentError => e
    puts "\nOops, something went wrong: #{e}\n"
    abort
  end
  print "Done!\n"
  return bestsellers, report
end

def write_file(report)
  filename = "simstore_report.html"
  File.write( filename, report )
  if File.exist?( filename )
    print "Done! Sales report saved: #{filename}"
  else
    print "Oops! Unable to save: #{filename}"
  end
end

def cat_bestsellers(arr)
  arr.map do |tr|
    sprintf("#%-02s %s by %s (SKU: %s) \n    Sold %s for %04s total revenue \n",
      tr[0], tr[3], tr[4], tr[1], tr[2], tr[5] )
  end.join("\n")
end

# Runtime
report, bestsellers = '', ''
welcome_msg

c = STDIN.getch
if c == 's'
  bestsellers, report = run_simulation(configure_store_options)
elsif c == 'd'
  bestsellers, report = run_simulation
else
  exit
end

print "\nSaving sales report ... "
write_file(report)

puts "\n\nHere are the bestsellers:\n\n"
puts cat_bestsellers(bestsellers)
puts ''
