require_relative './db_connection'

module Searchable
  def where(params)
  	where_clause = params.keys.map {|key| key = "#{key} = ?"}
  	query = <<-SQL
  	SELECT * 
  	FROM #{table_name}
  	WHERE #{where_clause.join(" AND ")}
  	SQL
  	DBConnection.execute(query, *params.values)
  end
end