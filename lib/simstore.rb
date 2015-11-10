$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'bundler/setup'
require 'models/constructor'
require 'models/janitor'
require 'controllers/input_validator'
require 'controllers/simulations'
require 'controllers/reports'

class SimStore
include Constructor
include Janitor
include Validator
include Simulations
include Reports

  attr_accessor :db, :db_name, :store_name, :date
  CONFIG = YAML::load_file("../config/config.yml")

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

  # TODO: save config options in a DB table
  # If a db_name is passed, and it exists, then don't overwrite the config

  private
  def validate_input
    validate_integer_arguments
    validate_dbname_argument
    @date = validate_date_argument(@date)
    validate_range_arguments
    warn_on_insufficient_stock
    return true
  end
end
