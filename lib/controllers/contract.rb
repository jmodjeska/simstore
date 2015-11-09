$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'faker'

# Build things that a store will need on a contract basis

module Contract

  def setup_vendor
    {
      :name => Faker::Company.name
    }
  end

  def setup_employee
    {
      :name  => Faker::Name.name,
      :title => Faker::Name.title
    }
  end
end
