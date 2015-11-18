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
  PROMOTIONS = CONFIG['promotions']
  VERSION = "0.3"

  def initialize ( options = {} )
    options.reject! { |o, v| v == 0 || v.to_s.empty? }
    defaults = CONFIG['defaults']

    if File.exist?( assemble_db_name( options[:db_name] ) )
      @db_name = assemble_db_name( options[:db_name] )
      @db = db_up
      Setting.create if Setting.first.nil?
      Setting.first.as_json.each do |var|
        instance_variable_set("@#{var[0]}", var[1])
      end
    else
      defaults[:date] = Time.now
      options[:db_name] = assemble_db_name( ('a'..'z').to_a.shuffle[0,32].join )
      (defaults.merge!options).each do |k, v|
        instance_variable_set("@#{k}", v)
      end
      validate_input
      @db = db_up
    end

    save_config
  end

  def save_config
    skips = ['@db', '@next_setup_step']
    Setting.create if Setting.first.nil?
    instance_variables.each do |var|
      varname = var.to_s
      next if skips.include?(varname)
      varname.slice!(0)
      Setting.first.update( varname => instance_variable_get(var) )
    end
  end

  private
  def validate_input
    validate_integer_arguments
    @date = validate_date_argument(@date)
    validate_range_arguments
    warn_on_insufficient_stock
    return true
  end
end
