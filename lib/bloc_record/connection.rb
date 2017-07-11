require 'sqlite3'
require 'pg'

module PG
	class Connection
		def execute(sql)
			self.exec(sql).values
		end

		def table_info(table, &block)
			sql = <<-SQL
				select column_name as name, data_type as type 
				from information_schema.columns 
				where table_name='#{table}'
			SQL
			rows = self.exec(sql)
			rows.each &block
		end
	end
end

module Connection
	def connection
		if BlocRecord.sqlserver == 'sqlite3'
			@connection ||= SQLite3::Database.new(BlocRecord.options)
		elsif BlocRecord.sqlserver == 'pg'
			# @connection ||= PG::Connection.new(dbname: BlocRecord.database_filename, user: "noel", password: "deguzman")
			@connection ||= PG::Connection.new(BlocRecord.options)
		end
	end
end
