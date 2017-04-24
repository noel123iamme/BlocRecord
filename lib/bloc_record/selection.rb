require 'sqlite3'

module Selection 
	def find(id)
		sql = <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			WHERE id = #{id};
		SQL
		puts sql
		get_first(sql)
	end

	def find_by(attribute, value)
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
		SQL
		puts sql
		get_first(sql)
	end

	def get_first(sql)
		row = connection.get_first_row sql 
		data = Hash[columns.zip(row)]
		new(data)
	end
end
