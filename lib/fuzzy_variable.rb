class FuzzyVariable

	attr_accessor :name, :partition

	def initialize name, partition
		@name = name
		@partition = partition.each_slice(2).map{|label, mf| FuzzySet.new mf, self, label}

		@partition.each{|fs|
			self.class.send(:define_method, "#{fs.label}") do
				fs
			end
		}

	end

	def self.find_best_fit partition, x
  		partition.max_by{|fs| fs.membership(x)}
  	end

  	def self.eval_truth data, filter, summary
		mfs = data.map{|el| summary.membership(el)}
		truth = filter.zip(mfs).map{|f, s| [f, s].min}.reduce(:+) * 1.0 / filter.reduce(:+)
  	end

  	def self.find_best_fit_fs fvariable, data, filter, threshold = 0.7
  		return EmptySet.new if data.empty?
  		partition = fvariable.partition
  		
  		ledge, redge = [:min, :max].map{|f| find_best_fit(partition, data.send(f))}
  		li, ri = [ledge, redge].map{|fs| partition.find_index(fs)}

  		#raise ledge.mf.inspect
  		b1, b2 = [ledge.mf, redge.mf.reverse]
  			.map{|mf| mf.find_index{|_, mf| mf == 1}}

  		init_fs = FuzzySet.new(ledge.mf.first(b1+1) + redge.mf.last(b2+1), fvariable).purify!

  		shrink_fs(partition, data, filter, threshold, init_fs, li, ri,
  			eval_truth(data, filter, init_fs))
  	end

	private

  	def self.shrink_fs partition, data, filter, threshold, cur_fs, li, ri, truth
  		reduced_l, reduced_r = [li, ri].map{|i|
  			FuzzySet.new(cur_fs.fuzzy_and(partition[i].fuzzy_not), cur_fs.variable).purify!}
		
		Rails.logger.debug  "Initial: #{cur_fs.mf} ; Candidates: #{reduced_l.mf} #{reduced_r.mf} #{partition[li].fuzzy_not}"
  		
  		return [cur_fs, truth] if reduced_l.mf.empty? || reduced_r.mf.empty?
		
		truth_l, thrith_r = [reduced_l, reduced_r].map{|fs| eval_truth(data, filter, fs)}

		#logger.debug "Truth: 1. #{truth_l.round(2)} 2. #{truth_r.round(2)}"

		return [cur_fs, truth] if ((truth_l < threshold && truth_r < threshold) || li == ri)

		result = []
		result << shrink_fs(partition, data, filter, threshold, reduced_l, truth_l, li+1, ri) if truth_l >= threshold
		result << shrink_fs(partition, data, filter, threshold, reduced_r, truth_r, li, ri-1) if truth_r >= threshold
		result.max
	end

end