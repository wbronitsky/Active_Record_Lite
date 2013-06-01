require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    if @params[:class_name] 
      @params[:class_name].constantize
    else
      @name.to_s.singularize.capitalize.constantize
    end
  end

  def other_table
    other_class.table_name
  end

  def primary_key
    @params[:primary_key] ? @params[:primary_key] : "id"
  end

end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name = name
    @params = params
  end

  def foreign_key
    @params[:foreign_key] ? @params[:foreign_key] : @name.to_s << "_id"
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @name = name
    @params = params
    @self_class = self_class
  end

  def foreign_key
    @params[:foreign_key] ? @params[:foreign_key] : @self_class.to_s.underscore << "_id"
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    assoc_params[name] = BelongsToAssocParams.new(name, params)
    define_method(name.to_s) do 
      aps = self.class.assoc_params[name]

      query = <<-SQL
      SELECT *
      FROM #{aps.other_table} 
      WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL

      row = DBConnection.execute(query, self.send(aps.foreign_key))
      aps.other_class.parse_all(row)
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      aps = HasManyAssocParams.new(name, params, self.class)
      query = <<-SQL
      SELECT *
      FROM #{aps.other_table}
      WHERE #{aps.foreign_key} = ?
      SQL
      row = DBConnection.execute(query, self.id)
      aps.other_class.parse_all(row)
    end


  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do 
      aps1 = self.class.assoc_params[assoc1]
      aps2 = aps1.other_class.assoc_params[assoc2]
      query = <<-SQL
      SELECT #{aps2.other_table}.*
      FROM #{aps1.other_table}
        JOIN #{aps2.other_table}
        ON #{aps1.other_table}.#{aps1.primary_key} = #{aps2.other_table}.#{aps2.primary_key}
      WHERE #{aps1.other_table}.#{aps1.primary_key} = ?
      SQL
      row = DBConnection.execute(query, self.id)
      aps2.other_class.parse_all(row)
    end

  end
end
