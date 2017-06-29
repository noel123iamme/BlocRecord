module BlocRecord
	class Collection < Array
		def update_all(updates)
			ids = self.map(&:id)
			self.any? ? self.first.class.update(ids, updates) : false
		end

		def take(num=1)
      if self.any?
        self[0..num-1]
      end
		end

		def where(*args)
      args.compact!
      if args.compact.count > 0
        ids = self.map(&:id)
        self.any? ? self.first.class.where(args.first, {ids: ids}) : false
      else
        self
      end
		end

    def not(*args)
      args.compact!
      if args.compact.count > 0
        ids = self.map(&:id)
        self.any? ? self.first.class.not(args.first, {ids: ids}) : false
      else
        self
      end
    end
	end
end
