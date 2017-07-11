require 'sqlite3'
require 'bloc_record/schema'

module Persistence
	def self.included(base)
		base.extend(ClassMethods)
	end 

	def save
		self.save! rescue false
	end

	def save!
		unless self.id
			self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
			BlocRecord::Utility.reload_obj(self)
			return true
		end

		fields = self.class.attributes.map { |col| 
			"#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}"
		}.join(",")

		sql = <<-SQL
			UPDATE #{self.class.table}
			SET #{fields}
			WHERE id = #{self.id}
		SQL
		self.class.connection.execute sql
		
		true
	end

	def update_attribute(attribute, value)
		self.class.update(self.id, {attribute => value})
	end

	def update_attributes(updates)
		puts "id: #{self.id}  update_attributes: #{updates}"
		self.class.update(self.id, updates)
	end

	def destroy
		self.class.destroy(self.id)
	end

	module ClassMethods
		def create(attrs)
			attrs = BlocRecord::Utility.convert_keys(attrs)
			attrs.delete "id"
			vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

			sql = <<-SQL 
				INSERT INTO #{table} (#{attributes.join ","})
				VALUES (#{vals.join ","});
			SQL
			connection.execute sql

			data = Hash[attributes.zip attrs.values]
			if BlocRecord.sqlserver == 'sqlite3'
			data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
		elsif BlocRecord.sqlserver == 'pg'
			data["id"] = connection.execute("SELECT currval(pg_get_serial_sequence('#{table}','id'));")[0][0]
		end
			new(data)
		end

		# update(1, {last_name: "Johnson", address: "123 This Street"})
		def update(ids, updates)
			if (ids.class == Array && updates.class == Array)
				for i in 0..updates.count - 1 do
					update_one(ids[i], updates[i])
				end
			else
				update_one(ids, updates)
			end
			true
		end

		def update_one(ids, updates)
			puts "ids.class: #{ids.class}"
			if ids.class == Fixnum || ids.class == String
				where_clause = "WHERE id = #{ids}"
			elsif ids.class == Array 
				where_clause = "WHERE id IN (#{ids.join ", "})"
			else
				where_clause = ""
			end
			updates = BlocRecord::Utility.convert_keys(updates)
			updates.delete "id"
			updates_array = updates.map { |key, value| "#{key} = #{BlocRecord::Utility.sql_strings(value)}" }
			sql = <<-SQL
				UPDATE #{table}
				SET    #{updates_array.join ", "}
				#{where_clause}
			SQL
			puts "update_one: #{sql}"
			connection.execute sql
			true
		end

		def update_all(updates)
			update(nil, updates)
		end

		def destroy(*id)
			unless id.empty?
				sql = <<-SQL
					DELETE FROM #{table} 
					WHERE id IN (#{id.join(", ")});
				SQL
				puts sql
				connection.execute sql 
				true 
			end
		end

		def destroy_all(conditions_hash=nil)
			unless conditions_hash.nil? || conditions_hash.empty?
				if conditions_hash.class == Hash
					conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
					conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
					where_clause = "WHERE #{conditions}"
				elsif conditions_hash.class == String 
					where_clause = "WHERE #{conditions_hash}"
				elsif conditions_hash.class == Array 
					where_clause = conditions_hash.shift
					params = conditions_hash
				else
					where_clause = ""
				end	
				sql = "DELETE FROM #{table} #{where_clause}"
				connection.execute(sql, params)
				true
			end
		end
	end
end
