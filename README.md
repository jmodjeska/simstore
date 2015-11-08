# SimStore
A simulated bookstore project for my Ruby class. Uses simple randomization to generate inventory, fake sales, and sales reports, including a Bestseller List.

## Installation
Installation is easy with bundler. Clone this repo and then run:
```
bundle install
```

## Configuration
Edit `config/config.yml` to adjust the variables that control the store's configuration. The `db_name` variable should remain empty unless you want to create/use a specific database file.

## Usage
#### Store Construction and Initial Setup
```
store = Simstore.new         #=> Creates a new store instance
store.populate_everything    #=> Builds all required lists, and simulates the first day's transactions
```
In lieu of `populate_everything` you can populate lists individually if you choose:
```
store.populate_vendors       #=> Builds vendor list
store.populate_products      #=> Builds product inventory
store.populate_transactions  #=> Simulates a day's sales
```

#### Reporting
```
TODO: Add Reporting Instructions
```

## Optional configuration arguments
Min/max options represent upper and lower bounds, and actual values are randomized in runtime.
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
