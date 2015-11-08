# SimStore
A simulated bookstore project for my Ruby class. Uses simple randomization to generate inventory, fake sales, and sales reports, including a Bestseller List.

## Installation
Installation is easy with bundler. Clone this repo and then run:
```
bundle install
```

## Configuration
Edit `config/config.yml` to adjust the variables that control the store's configuration. The `db_name` variable should remain empty unless you want to create/use a specific database file. Min/max options represent upper and lower bounds; actual values are randomized in runtime.
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

## Usage
#### Store Construction and Initial Setup
Constuct and populate a store, and run a day's sales:
```
store = Simstore.new         #=> Creates a new store instance
store.populate_everything    #=> Builds all required lists, and simulates the first day's transactions
```
Run additional days' sales:
```
store.update_date(new_date in mm-dd-yyyy format)
store.populate_transactions
```
In lieu of `populate_everything` you can (re-)populate lists individually for fun and profit. The following syntax works for `employees`, `vendors`, `products`, and `transactions`:
```
store.clean_table("employees") #=> Fire all existing employees
store.populate_employees       #=> Get some new employees
```

#### Reporting
```
TODO: Add Reporting Instructions
```
