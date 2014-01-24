class Miner < ActiveRecord::Base
	
	attr_accessible :group, :age, :profession, :emg_a, :emg_ka

	cattr_reader :attr_of_interest, :fuzzy_attr, :crisp_attr, :attr

	def self.attr_of_interest
		@@attr_of_interest ||= [:group, :age, :profession, :emg_a, :emg_ka]
	end

  	# FS generation

  	def self.gen_fs(min, max, step)
  		[("less_than_#{min}").to_sym, [min-step, 1, min, 0]] +
  		Array((min..max).step(step)).flat_map{|head| [("about_#{head}").to_sym, [head-step, 0, head, 1, head+step, 0]]} +
  		[("more_than_#{max}").to_sym, [max-step, 0, max, 1]]
  	end

	def self.fuzzy_attr
		@@fuzzy_attr ||= {
			#age: [
			#	:young, [25, 1, 40, 0],
			#	:middle_aged, [25, 0, 40, 1, 50, 1, 65, 0],
			#	:old, [50, 0, 65, 1]
			#,
			emg_a: self.gen_fs(550, 1300, 25)
		}
	end

	self.fuzzy_attr.each do |attr, fs|
		fs.each_slice(2) do |name, mf|
			define_method(name.to_s + '?') do
				Miner.build_fs mf, send(attr)
			end
			define_singleton_method('get_fs_' + name.to_s) do
				mf
			end
		end
	end

	def self.crisp_attr
		@@crisp_attr ||= {
			group: [:main, :control],
			profession: [:drill_runner, :loader_operator, :stope_miner, :shaftman, :timberman]
		}
	end

	self.crisp_attr.each do |attr, val|
		val.each do |name|
			define_method(name.to_s + '?') do
				send(attr) == name.to_s ? 1 : 0
			end
		end
	end

	def self.attributes
		@@attr = @@fuzzy_attr.inject({}) {|h, el| h[el[0]] = el[1].select{|x| x.class == Symbol}; h}
			.merge @@crisp_attr
	end

	# BEGIN This should be in lib

	def self.build_fs m, x
		return m[1] if x <= m[0]
		return m[m.count - 1] if x >= m[m.count - 2]
		i = 2
		while(x > m[i]); i += 2; end
		1.0 * ((x - m[i - 2])*(m[i + 1] - m[i - 1])) / (m[i] - m[i - 2]) + m[i - 1]
	end

	def self.aggregate data, attrs
		(data.map{ |row|
			attrs.map{|attr| attr.kind_of?(Array) ? build_fs(attr[1], row.send(attr[0])) : row.send(attr.to_s + '?')}.min
		}.reduce(:+) * 1.0)
	end

	def self.most x
  		#Miner.build_fs [0.3, 0, 0.8, 1], x
  		Miner.build_fs [0, 0, 1, 1], x
  	end

	def self.summary? data, filter, summary
		truth = most(aggregate(data, filter + summary) /
			(filter.empty? ? data.count : aggregate(data, filter))) * 1.0
		truth.nan? ? 0.0 : truth
  	end

  	def self.fs_values fs
  		fs.each_slice(2).map{|x, _| x}
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

  	def self.query data, filter
  		return data.map{|el| [el, 1.0]} if filter.empty?
  		data.map{ |el|
			[el, filter.map{|attr| el.send(attr.to_s + '?')}.min]
		}.select{|el, mf| mf > 0}
	end

  	def self.candidates summary = :emg_a
  		prod = attributes.values[0]
  		attributes.values[1..-1].each do |params|
  			prod = prod.product([nil] + params).map{|x| x.flatten.select{|x| !x.nil?} }
  		end
  		prod.flat_map {|comb| comb.map{|el| [comb - [el], [el]]}}.select{|s| attributes[summary].include? s[1][0]}
  	end

  	def self.gen_filters params
  		prod = attributes[params[0]].map{|at| [at]}
  		params[1..-1].each do |param|
  			prod = prod.product([nil] + attributes[param]).map{|x| x.flatten.select{|x| !x.nil?} }
  		end
  		prod
   	end		

  	def self.find_best_fit_fs param, x
  		attributes[param].map{|lab| fs = send("get_fs_#{lab}"); [lab, fs, build_fs(fs,x)]}
  			.max_by{|x| x[2]}
  	end

  	def self.find_best_fit data, filter, sum_param
  		data = query(data, filter).map{|x, _| x}
  		return [0, 0] if data.empty?
  		left = find_best_fit_fs(sum_param, data.min_by{|el| el[sum_param]}[sum_param])
  		right = find_best_fit_fs(sum_param, data.max_by{|el| el[sum_param]}[sum_param])

  		li = fuzzy_attr[sum_param].find_index(left[0])
  		ri = fuzzy_attr[sum_param].find_index(right[0])

  		b1 = left[1].each_slice(2).find_index{|_, mf| mf == 1}
  		b2 = right[1].each_slice(2).to_a.reverse.find_index{|_, mf| mf == 1}
  		new_fs = left[1].first(b1*2+2) + right[1].last(b2*2 + 2)
  		fs, truth = shrink_fs(data, filter, sum_param, new_fs, summary?(data, filter, [[sum_param, new_fs]]), li, ri)
  		[purify_fs(fs.each_slice(2).to_a), truth] 		
  	end

  	def self.shrink_fs data, filter, target_param, cur_fs, truth, li, ri


  		left = fuzzy_attr[target_param][li+1]
  		right = fuzzy_attr[target_param][ri+1]
  		reduced_l = fuzzy_and(cur_fs, fuzzy_not(left))
  		reduced_r = fuzzy_and(cur_fs, fuzzy_not(right))
  		#logger.debug  "#{left} #{right} #{reduced_l} #{reduced_r}"
  		return [cur_fs, truth] if reduced_l.empty? || reduced_r.empty?
		truth_l = summary?(data, filter, [[target_param, reduced_l]])
		truth_r = summary?(data, filter, [[target_param, reduced_r]])

		logger.debug "#{filter} #{cur_fs} -> #{reduced_l} #{truth_l} #{reduced_r} #{truth_r}"

		threshold = 0.7

		return [cur_fs, truth] if ((truth_l < threshold && truth_r < threshold) || li == ri)
		return shrink_fs(data, filter, target_param, reduced_l, truth_l, li+2, ri) if truth_r < threshold
		return shrink_fs(data, filter, target_param, reduced_r, truth_r, li, ri-2) if truth_l < threshold
		[shrink_fs(data, filter, target_param, reduced_l, truth_l, li+2, ri),
			shrink_fs(data, filter, target_param, reduced_r, truth_r, li, ri-2)].max_by{|_, t| t}
	end

	def self.fs_to_s fs
		if fs[1] == 1
			return "less_than_#{fs[0]}"
		end
		if fs[fs.count-1] == 1
			return "more_than_#{fs[fs.count-2]}"
		end
		return "about_#{fs[2]}-#{fs[4]}"
	end

end
