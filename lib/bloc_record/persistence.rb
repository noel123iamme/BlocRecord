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
			data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
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
			if ids.class == Fixnum
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
			connection.execute sql
			true
		end

		def update_attribute(attribute, value)
			self.class.update(self.id, {attribute => value})
		end

		def update_attributes(updates)
			self.class.update(self.id, updates)
		end

		def update_all(updates)
			update(nil, updates)
		end
	end
end
