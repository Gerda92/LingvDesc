class CrispSet
	attr_accessor :label, :mf, :variable

	def initialize variable, label = nil
		@variable = variable
		@label = label
	end

	def membership x
		@label == x ? 1.0 : 0
	end
end