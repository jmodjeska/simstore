require 'active_record'
require 'sqlite3'

module Constructor
  SCHEMA = YAML.load_file("../config/db_schema.yml")

  def db_up
    access_or_create_db
    create_table_schema
    return ActiveRecord::Base
  end

  def access_or_create_db
    SQLite3::Database.new @db_name unless File.exist?(@db_name)
    ActiveRecord::Base.logger = Logger.new("../data/ssdb.log")
    ActiveRecord::Base.establish_connection(
      :adapter  => 'sqlite3',
      :database => @db_name
    )
  end

  def create_table_schema
    ActiveRecord::Schema.define do
      SCHEMA.each do |table_def|
        unless ActiveRecord::Base.connection.table_exists? table_def[0]
          create_table table_def[0] do |table|
            table_def[1].each { |col, type| table.column col, type }
          end
        end
      end
    end
  end

  def db_down
    begin
      ActiveRecord::Base.clear_active_connections!
      File.delete(@db_name)
    rescue Errno::ENOENT => e
      warn "Could not delete the DB #{@db_name}: #{e}"
    end
  end
end
