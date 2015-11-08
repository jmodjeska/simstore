require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'models/constructor'
require 'models/janitor'
require 'controllers/input_validator'
require 'controllers/simulations'

class SimStore
include Constructor
include Janitor
include Validator
include Simulations

  attr_accessor :db, :db_name
  CONFIG = YAML.load_file("../config/config.yml")

  def initialize ( options = {} )
    options.reject! { |o, v| v == 0 || v.to_s.empty? }
    defaults = CONFIG['defaults']
    defaults[:date] = Time.now
    defaults[:db_name] = ('a'..'z').to_a.shuffle[0,32].join
    (defaults.merge!options).each do |k, v|
      instance_variable_set("@#{k}", v)
    end
    validate_input
    @db = db_up
  end

  def update_date(new_date)
    @date = new_date
    validate_date_arguments
  end

  private
  def validate_input
    validate_integer_arguments
    validate_dbname_argument
    validate_date_arguments
    validate_range_arguments
    warn_on_insufficient_stock
    return true
  end
end
