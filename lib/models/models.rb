require 'active_record'

# Describe relationships between a store's constituent parts

module Models

  class Product < ActiveRecord::Base
    belongs_to :vendor
    has_many   :transactions
  end

  class Transaction < ActiveRecord::Base
    belongs_to :employee
    belongs_to :product
  end

  class Vendor < ActiveRecord::Base
    has_many   :products
  end

  class Employee < ActiveRecord::Base
    has_many   :transactions
  end
end
