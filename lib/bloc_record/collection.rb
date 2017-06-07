module BlocRecord
	class Collection < Array
		def update_all(attributes)
			ids = self.map(&:id)
			self.any? ? self.first.class.update(ids, updates) : false
		end
	end
end
