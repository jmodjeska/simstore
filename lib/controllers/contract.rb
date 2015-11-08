$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'faker'

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
