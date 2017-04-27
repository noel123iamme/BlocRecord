require 'sqlite3'

module Selection 
	def find(*ids)
		if ids.length == 1
			find_one(ids.first)
		else
			sql = <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				WHERE id IN (#{ids.join(",")});
			SQL
			puts sql
			rows = connection.execute sql 
			rows_to_array(rows)
		end
	end

	def find_one(id)
		sql = <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			WHERE id = #{id};
		SQL
		puts sql
		row = connection.get_first_row sql 
		init_object_from_row(row)
	end

	def find_by(attribute, value)
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
		SQL
		puts sql
		row = connection.get_first_row sql 
		init_object_from_row(row)
	end

	def take_one
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY random()
			LIMIT 1;
		SQL
		puts sql
		row = connection.get_first_row sql
		init_object_from_row(row)
	end

	def take(num=1)
		if num > 1
			sql = <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				ORDER BY random()
				LIMIT #{num};
			SQL
			puts sql
			rows = connection.get_first_row sql
			rows_to_array(row)
		else
			take_one
		end
	end

	def first
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY id ASC
			LIMIT 1;
		SQL
		puts sql
		row = connection.get_first_row sql
		init_object_from_row(row)
	end

	def last
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY id DESC
			LIMIT 1;
		SQL
		puts sql
		row = connection.get_first_row sql
		init_object_from_row(row)
	end

	def all
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table};
		SQL
		puts sql
		rows = connection.execute sql
		rows = rows_to_array(rows)
		# puts rows
		rows
	end

	private 

	def init_object_from_row(row)
		if row
			data = Hash[columns.zip(row)]
			new(data)
		end
	end

	def rows_to_array(rows)
		rows.map { |row| new(Hash[columns.zip(row)]) }
	end
end
