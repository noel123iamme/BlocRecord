require 'sqlite3'
require_relative 'selection'

module ErrorHandling
	def method_missing(m, *args, &block)
		puts "#{m}"
		marr = m.to_s.split("_")
		if marr[0..1].join("_") == "find_by"
			att = marr[2..m.length-2].join("_")
			puts "find_by(#{att}, #{args[0].to_s})"
			row = find_by(att, args[0].to_s)
		else
			puts "No method #{m}"
			super
		end
		row
	end
end
