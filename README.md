# SimStore
A simulated bookstore project for my Ruby class. Uses simple randomization to generate inventory, fake sales, and sales reports, including a Bestseller List.

## Installation
Installation is easy with [bundler](http://bundler.io/). Clone this repo and then run:
```
cd simstore
bundle install
```

## Start the Web UI
Setup, configure, and report on a store via your browser: 
```
cd lib/controllers/
ruby server.rb
```
Now browse to [http://localhost:8000/](http://localhost:8000/)

## Development and Command Line Interaction with the SimStore Class
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
store.add_stock               # Optional
store.goto_next_day
store.populate_transactions
```
#### Setup promotions:
Modify promotion logic in `config.yml`, then apply promotions to selected products. Next time you simulate sales for this store, promotion logic will be in effect for the selected products.
```
store.assign_promotions_to_products            # Assign random promotions to 10% of products
store.activate_promotion(product_id, promo_id) # Assign promotion to a specific product
```

## Configuration
Edit `config/config.yml` to adjust the variables that control the store's configuration, or pass configuration options as arguments to `simstore.rb` in a hash. The `db_name` variable should remain empty unless you want to create/use a specific database file. Min/max options represent upper and lower bounds; actual values are randomized in runtime.
