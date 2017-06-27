require 'sqlite3'
require_relative 'selection'

module ErrorHandling
	def method_missing(m, *args, &block)
		marr = m.to_s.split("_")
		if marr[0] == "update"
			att = marr[1..m.length-2].join("_")
			row = update_attribute(att, args[0].to_s)
		elsif marr[0..1].join("_") == "find_by"
			att = marr[2..m.length-2].join("_")
			row = find_by(att, args[0].to_s)
		else
			super
		end
		row
	end
end
