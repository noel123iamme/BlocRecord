require 'sqlite3'

module Selection 

	def all
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table};
		SQL
		puts sql
		rows = connection.execute sql
		rows_to_array(rows)
	end

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

	def find_by(attribute, value)
		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
		SQL
		puts sql
		row = connection.get_first_row sql 
		init_object_from_row(row)
	end

	def find_each(options = {}, &block)
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

	def join(*args)
		if args.count > 1
			joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}
			sql = <<-SQL
				SELECT * FROM #{table} #{joins}
			SQL
		else
			case args.first 
			when String 
				sql = <<-SQL
					SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
				SQL
			when Symbol 
				sql = <<-SQL
					SELECT * FROM #{table}
					INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
				SQL
			end
		end
		rows = connection.execute sql 
		rows_to_array(rows)
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

	def order(*args)
		if args.count > 1
			order = args.join(",")
		else
			order = args.first.to_s
		end

		sql = <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY #{order}
		SQL

		rows = connection.execute(sql)
		rows_to_array(rows)		
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

	def where(*args)
		if args.count > 1
			expression = args.shift
			params = args
		else
			case args.first 
			when String 
				expression = args.first 
			when Hash 
				expression_hash = BlocRecord::Utility.convert_keys(args.first)
				expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
			end
		end

		sql = <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{expression}
		SQL

		rows = connection.execute(sql, params)
		rows_to_array(rows)
	end

	private 

	def init_object_from_row(row)
		new(Hash[columns.zip(row)]) if row
	end

	def rows_to_array(rows)
		rows.map { |row| new(Hash[columns.zip(row)]) }
	end
end
