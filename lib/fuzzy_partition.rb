class FuzzyPartition

	def self.find_best_fit_fs partition, x
  		partition.max_by{|fs| fs.membership(x)}
  	end

  	def self.find_best_fit_fs partition, data, filter, threshold = 0.7
  		return FuzzySet.new_empty if data.empty?
  		
  		boundary1, boudary2 = [:min, :max].map{|f| find_best_fit_fs(partition, data.send(f))}
  		li, ri = [ledge, redge].map{|fs| partition.find_index(fs.label)}

  		b1, b2 = [boundary1.mf, boundary2.mf.reverse]
  			.map{|mf| mf.find_index{|_, mf| mf == 1}}
  		init_fs = FuzzySet.new(boudary1.mf.first(b1*2+2) + boundary2.mf.last(b2*2+2)).purify

  		shrink_fs(partition, data, filter, threshold, init_fs, li, ri,
  			FuzzySummarizer.summary?(data, filter, init_fs))
  	end

	private

  	def self.shrink_fs partition, data, filter, threshold, cur_fs, li, ri, truth

  		reduced_l, reduced_r = [li, ri].map{|i|
  			fuzzy_and(cur_fs, fuzzy_not(partition[i])}
		
		#logger.debug  "Initial: #{cur_fs} ; Candidates: #{reduced_l} #{reduced_r}"
  		
  		return [cur_fs, truth] if reduced_l.empty? || reduced_r.empty?
		
		truth_l, thrith_r = [reduced_l, reduced_r].map{|fs| summary?(data, filter, fs)}

		#logger.debug "Truth: 1. #{truth_l.round(2)} 2. #{truth_r.round(2)}"

		return [cur_fs, truth] if ((truth_l < threshold && truth_r < threshold) || li == ri)

		result = []
		result << shrink_fs(partition, data, filter, threshold, reduced_l, truth_l, li+1, ri) if truth_l >= threshold
		result << shrink_fs(partition, data, filter, threshold, reduced_r, truth_r, li, ri-1) if truth_r >= threshold
		result.max
	end
end