class FuzzySet

	def initialize mf, label = nil
		@mf = mf
		@label = label
	end

	def self.membership mf, x
		return mf[1] if x <= mf[0]
		return mf[mf.count - 1] if x >= mf[mf.count - 2]
		i = 2
		while(x > mf[i]); i += 2; end
		1.0 * ((x - mf[i - 2])*(mf[i + 1] - mf[i - 1])) / (mf[i] - mf[i - 2]) + mf[i - 1]
	end

  	def self.fs_values fs
  		fs.each_slice(2).map{|x, _| x}
  	end

  	def self.heads fs
  		fs.each_slice(2).select{|x, mf| mf == 1}.map{|x, _| x}
  	end

  	def self.to_s fs
		if fs[1] == 1
			return "less_than_#{fs[0]}"
		end
		if fs[fs.count-1] == 1
			return "more_than_#{fs[fs.count-2]}"
		end
		return "about_#{fs[2]}-#{fs[4]}"
	end

	def self.purify_fs raw
   		Array(0..(raw.count-1)).map{|i| ((i==0 && raw[i+1][1]!=raw[i][1]) || (i==raw.count-1 && raw[i-1][1]!=raw[i][1]) ||
  			(i>0 && raw[i-1][1]!=raw[i][1]) || (i<raw.count-1 && raw[i+1][1]!=raw[i][1]))}.zip(raw).select{|i, x| i}
  			.map{|_, x| x}.flatten
  	end 		

  	def self.fuzzy_not a
  		a.each_slice(2).flat_map{|x, mf| [x, 1-mf]}
  	end

  	def self.fuzzy_and a, b
  		purify_fs(fs_values(a+b).uniq.sort.map{|x, mf| [x, [build_fs(a, x), build_fs(b, x)].min]})
  	end

  	def self.fuzzy_operation op, a, b
  		cp = fs_values(a).product(fs_values(b))
  			.map{|x, y| [x.send(op, y), [build_fs(a, x), build_fs(b, y)].min]}
  		raw = cp.uniq{|x, mf| x}.map{|x, mf| cp.select{|y, _| y == x}.max_by{|_, m| m}}
  			.sort_by{|x, mf| x}
  		Array(0..(raw.count-1)).map{|i| ((i==0 && raw[i+1][1]!=raw[i][1]) || (i==raw.count-1 && raw[i-1][1]!=raw[i][1]) ||
  			(i>0 && raw[i-1][1]!=raw[i][1]) || (i<raw.count-1 && raw[i+1][1]!=raw[i][1]))}.zip(raw).select{|i, x| i}
  			.map{|_, x| x}.flatten
  	end

end