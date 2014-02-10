module FuzzySummarizer

	def self.included base
		#base.send :include, InstanceMethods
		base.extend ClassMethods
	end

	module ClassMethods

		def define_fuzzy_variables vars
			@@fuzzy_vars = vars.map{|k, v| FuzzyVariable.new k, v}

			@@fuzzy_vars.each do |var|
				define_singleton_method("#{var.name}") do
					var
				end
				var.partition.each do |fs|
					define_method("#{fs.label}?") do
						fs.membership send(var.name)
					end
				end
			end
		end

		def define_crisp_variables vars
			@@crisp_vars = vars.map{|k, v| CrispVariable.new k, v}

			@@crisp_vars.each do |var|
				define_singleton_method("#{var.name}") do
					var
				end
				var.partition.each do |cs|
					define_method("#{cs.label}?") do
						send(var.name) == cs.label.to_s ? 1 : 0
					end
				end
			end
		end

		def attributes
			@@fuzzy_vars + @@crisp_vars
		end

	  	def query filter, data = all
	  		return data.map{|el| {element: el, membership: 1.0}} if filter.empty?
	  		data.map{ |el|
				{element: el, membership: filter.map{|fs| el.send("#{fs.label}?")}.min}
			}.select{|el| el[:membership] > 0}
		end

		def summary? data, filter, summary
			FuzzyVariable.eval_truth(data.map{|el| el[summary.variable.name]},
				query(filter, data).map{|el| el[:membership]}, summary.mf)
	  	end

		def good_summary fvariable, data, filter
			FuzzyVariable.find_best_fit_fs(fvariable, data.map{|el| el[fvariable.name]},
				query(filter, data).map{|el| el[:membership]})
	  	end

	  	def gen_filters params
	  		prod = params[0].partition.map{|fs| [fs]}
	  		params[1..-1].each do |param|
	  			prod = prod.product([nil] + param.partition).map{|x| x.flatten.select{|x| !x.nil?} }
	  		end
	  		prod
	   	end

	end

end