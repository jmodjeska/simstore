require 'active_record'
require 'sqlite3'

module Janitor

  def clean_database
    @db.connection.tables.each do |table_name|
      @db.connection.execute("DELETE FROM #{table_name}")
    end
  end

  def clean_table(table_name)
    @db.connection.execute("DELETE FROM #{table_name}")
  end
end
