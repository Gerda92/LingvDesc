class CrispVariable
	attr_accessor :name, :partition

	def initialize name, partition
		@name = name
		@partition = partition.map{|cs| CrispSet.new self, cs}

		@partition.each{|cs|
			self.class.send(:define_method, "#{cs.label}") do
				cs
			end
		}
	end
end