# SimStore
A simulated bookstore project for my Ruby class. Uses simple randomization to generate inventory, fake sales, and sales reports, including a Bestseller List.

# Usage
```
store = Simstore.new    #=> Creates a new store instance
store.populate_stock    #=> Creates an inventory that can be sold
store.run_business_day  #=> Simulate a day's sales
store.report_sales      #=> Return sales/bestseller report in HTML format
```
Other methods are accessible, as demonstrated in [bestseller.rb](https://github.com/jmodjeska/simstore/blob/master/scripts/bestseller.rb).

## Optional configuration arguments
Arguments represent max/min values. Actual values are randomized in runtime.
```
:max_daily_transactions
:min_stock_per_item    
:max_stock_per_item    
:unique_items          
:date
```


