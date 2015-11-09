# SimStore
A simulated bookstore project for my Ruby class. Uses simple randomization to generate inventory, fake sales, and sales reports, including a Bestseller List.

## Installation
Installation is easy with bundler. Clone this repo and then run:
```
bundle install
```

## Interactive Usage on the Command Line
Setup, configure, and report on a store by running [store_manager.rb](https://github.com/jmodjeska/simstore/blob/master/lib/views/store_manager.rb). Any reports you generate are saved in `/output`.

## Development Using the SimStore Class
#### Easy store setup and first day's sales
Constuct and populate a store, and run a day's sales using config values assigned in `config.yml`:
```
store = Simstore.new         #=> Creates a new store instance
store.populate_everything    #=> Builds all required lists, and simulates the first day's transactions
```
#### Customized setup
Construct and populate a store, overriding some of the default config options:
```
store = Simstore.new( :max_daily_transactions => 200, :db_name => 'jeremy' )
```
In lieu of `populate_everything` you can (re-)populate lists individually for fun and profit. The following syntax works for `employees`, `vendors`, `products`, and `transactions`:
```
store.clean_table("employees") #=> Fire all existing employees
store.populate_employees       #=> Get some new employees
```
#### Run additional days' sales:
```
store.update_date(new_date in yyyy-mm-dd format)
store.populate_transactions
```

## Configuration
Edit `config/config.yml` to adjust the variables that control the store's configuration, or pass configuration options as arguments to `simstore.rb` in a hash. The `db_name` variable should remain empty unless you want to create/use a specific database file. Min/max options represent upper and lower bounds; actual values are randomized in runtime.
```
:max_daily_transactions: 800
:min_stock_per_item: 3
:max_stock_per_item: 47
:max_price: 100
:unique_items: 100
:vendors: 5
:employees: 6
:db_name:
```

## Reporting
The [reports](https://github.com/jmodjeska/simstore/blob/master/lib/controllers/reports.rb) module contains logic to build common reports. There are also numerous [queries](https://github.com/jmodjeska/simstore/blob/master/lib/models/queries.rb) available so you can roll your own.
