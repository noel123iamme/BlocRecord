require 'sqlite3'

module Selection 
	def find(*ids)
		if ids.length == 1
			find_one(ids.first)
		elsif ids.length > 1
			if BlocRecord::Utility.valid_ids?(ids)
				sql = <<-SQL
					SELECT #{columns.join ","} FROM #{table}
					WHERE id IN (#{ids.join(",")});
				SQL
				puts sql
				rows = connection.execute sql 
				rows_to_array(rows)
			else
				puts "Invalid IDs #{ids}"
			end
		end
	end

	def find_one(id)
		if BlocRecord::Utility.is_pos_int?(id)
			sql = <<-SQL 
				SELECT #{columns.join ","} FROM #{table}
				WHERE id = #{id};
			SQL
			puts sql
			row = connection.get_first_row sql 
			init_object_from_row(row)
		end
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
		if BlocRecord::Utility.is_pos_int?(num)
			if num > 1
				sql = <<-SQL
					SELECT #{columns.join ","} FROM #{table}
					ORDER BY random()
					LIMIT #{num};
				SQL
				puts sql
				rows = connection.execute sql
				rows_to_array(rows)
			else
				take_one
			end
		else
			puts "Invalid arg: #{num}"
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

	def find_each(options = {}, &block)
		# offset = options.has_key?(:start) ? "OFFSET #{options[:start]}" : ""
		# limit = options.has_key?(:batch_size) ? "LIMIT #{options[:batch_size]}" : "LIMIT #{count}" 
		# sql = <<-SQL
		# 	SELECT #{columns.join ","} FROM #{table}
		# 	ORDER BY id
		# 	#{limit} #{offset};
		# SQL
		# puts sql
		# rows = connection.execute sql
		# rows = rows_to_array(rows)
		# yield rows if block_given?
		if block_given?
			find_in_batches(options) do | records, batch |
				records.each do | record |
					yield record
				end
				break
			end
		end
	end

	def find_in_batches(options={}, &block)
		start = options.has_key?(:start) ? options[:start] : 0
		batch_size = options.has_key?(:batch_size) ? options[:batch_size] : 100
		batch = 1
		while start < count
			sql = <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				ORDER BY id
				LIMIT #{batch_size} OFFSET #{start};
			SQL
			puts sql
			rows = connection.execute sql
			rows = rows_to_array(rows)
			
			yield rows, batch if block_given?
			
			start += batch_size
			batch += 1
		end
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
