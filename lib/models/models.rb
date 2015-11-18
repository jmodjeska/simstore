require 'active_record'

# Describe relationships between a store's constituent parts

module Models

  class Setting < ActiveRecord::Base
  end

  class Product < ActiveRecord::Base
    belongs_to :vendor
    has_many   :transactions
    has_one    :promotion
  end

  class Transaction < ActiveRecord::Base
    belongs_to :employee
    belongs_to :product
  end

  class Vendor < ActiveRecord::Base
    has_many   :products
    has_many   :transactions
  end

  class Employee < ActiveRecord::Base
    has_many   :transactions
  end

  class Promotion < ActiveRecord::Base
    belongs_to :product
  end
end
