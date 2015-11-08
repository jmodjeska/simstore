class RandomConfig
  attr_reader :config
  def initialize
    offset = rand(0..365) * 86400 # days
    @config = {
      :unique_items           => rand(10..201),
      :min_stock_per_item     => rand(1..21),
      :max_stock_per_item     => rand(22..37),
      :max_daily_transactions => rand(20..1001),
      :date                   => Time.now + offset
    }
  end
end
