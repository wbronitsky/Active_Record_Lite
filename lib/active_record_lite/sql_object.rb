require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject

  extend Associatable
  extend Searchable

  def self.set_table_name(table_name)
    table_name = table_name.underscore
    attr_accessor :table_name
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    table = DBConnection.execute("SELECT * FROM #{@table_name}" )
    table.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    row = DBConnection.execute("Select * FROM #{@table_name} WHERE id = ?", id).first
    new(row)
  end

  def create
    attributes = self.class.attributes.join(",")
    question_marks = ["?"] * self.class.attributes.count
    DBConnection.execute(
      "INSERT INTO #{self.class.table_name} 
      (#{attributes})
        VALUES (#{question_marks.join(",")})", 
      *attribute_values
      )

    self.id = DBConnection.last_insert_row_id

  end

  def update
    attribute_names = self.class.attributes.map do |attr|
      attr = "#{attr} = ?"
    end.join(", ")
    query = <<-SQL
    UPDATE #{self.class.table_name}
      SET #{attribute_names}
      WHERE id = #{self.id}
      SQL
    DBConnection.execute(query, *attribute_values)
  end

  def save
    self.id == nil ? create : update
  end

  def attribute_values
    self.class.attributes.map {|attribute| send(attribute)}
  end
end
