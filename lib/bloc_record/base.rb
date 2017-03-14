require 'utility'
require 'schema'
require 'persistence'
require 'selection'
require 'connection'

module BlocRecord
	class Base
		include Persistence 
		extend Selection 
		extend Schema 
		extend Connection 

		def initilize(options={})
			options = BlocRecord::Utility.convert_keys(options)

			self.class.columns.each do |col|
				self.class.send(:attr_accessor, col)
				self.instance_variable_set("@#{col}}", options[col])
			end
		end
	end
end
