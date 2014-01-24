module FuzzySummarizer

  	def self.query filter
  		return all.map{|el| [el, 1.0]} if filter.empty?
  		all.map{ |el|
			[el, filter.map{|attr| el.send("#{attr}?")}.min]
		}.select{|el, mf| mf > 0}
	end

	def self.summary? data, filter, summary
		mfs = data.map{|el| summary.membership(el)}
		truth = filter.zip(mfs).map{|f, s| [f, s].min}.reduce(:+) * 1.0 / filter.reduce(:+)
  	end

  	def self.gen_filters params
  		prod = attributes[params[0]].map{|at| [at]}
  		params[1..-1].each do |param|
  			prod = prod.product([nil] + attributes[param]).map{|x| x.flatten.select{|x| !x.nil?} }
  		end
  		prod
   	end

end