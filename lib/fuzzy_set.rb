class FuzzySet

	attr_accessor :label, :mf, :variable

	def initialize mf, variable, label = nil
		@mf = mf.each_slice(2).to_a
		@variable = variable
		@label = label
	end

	def membership(x) self.class.membership(x, @mf.flatten) end

	def to_s() self.class.to_s(@mf) end

	def fuzzy_not() self.class.fuzzy_not(@mf) end

	def fuzzy_and(b) self.class.fuzzy_and(@mf, b) end

	def mf_values() self.class.mf_values(@mf) end

	def heads() self.class.heads(@mf) end

	def purify!() @mf = self.class.purify_mf(@mf); self end

	def self.membership x, mf
		return mf[1] if x <= mf[0]
		return mf[mf.count - 1] if x >= mf[mf.count - 2]
		i = 2
		while(x > mf[i]); i += 2; end
		1.0 * ((x - mf[i - 2])*(mf[i + 1] - mf[i - 1])) / (mf[i] - mf[i - 2]) + mf[i - 1]
	end

	def self.to_s mf
		return @label if !@label.nil?
		if mf[1] == 1
			return "less_than_#{mf[0]}"
		end
		if mf[mf.count-1] == 1
			return "more_than_#{mf[mf.count-2]}"
		end
		if mf.count == 6
			return "about_#{mf[2]}"
		end
		return "about_#{mf[2]}-#{mf[4]}"
	end

  	def self.fuzzy_not a
  		a.flat_map{|x, mf| [x, 1-mf]}
  	end

  	def self.fuzzy_and a, b
  		purify_mf(mf_values(a+b).uniq.sort.map{|x, mf| [x, [membership(x, a), membership(x, b)].min]})
  	end

  	def self.mf_values mf
  		mf.map{|x, _| x}
  	end

  	def self.heads
  		mf.select{|x, mf| mf == 1}.mf_values
  	end

	def self.purify_mf raw
   		Array(0..(raw.count-1)).map{|i| ((i==0 && raw[i+1][1]!=raw[i][1]) || (i==raw.count-1 && raw[i-1][1]!=raw[i][1]) ||
  			(i>0 && raw[i-1][1]!=raw[i][1]) || (i<raw.count-1 && raw[i+1][1]!=raw[i][1]))}.zip(raw).select{|i, x| i}
  			.map{|_, x| x}.flatten
  	end

  	def self.gen_fs(min, max, step)
  		[("less_than_#{min}").to_sym, [min-step, 1, min, 0]] +
  		Array((min..max).step(step)).flat_map{|head| [("about_#{head}").to_sym, [head-step, 0, head, 1, head+step, 0]]} +
  		[("more_than_#{max}").to_sym, [max-step, 0, max, 1]]
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