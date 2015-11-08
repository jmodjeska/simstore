require 'active_record'

module Models

  class Product < ActiveRecord::Base
    belongs_to :vendor
    has_many   :transactions
    has_one    :volume
  end

  class Transaction < ActiveRecord::Base
    belongs_to :employee
    has_one    :product
  end

  class Vendor < ActiveRecord::Base
    has_many   :products
  end

  class Volume < ActiveRecord::Base
    belongs_to :product
  end

  class Employee < ActiveRecord::Base
    has_many   :transactions
  end
end
