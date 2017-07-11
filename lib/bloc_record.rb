module BlocRecord
	def self.connect_to(options, sqlserver)
		@options, @sqlserver = options, sqlserver.to_s
	end

	def self.options
		@options
	end

	def self.sqlserver
		@sqlserver
	end
end
