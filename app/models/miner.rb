class Miner < ActiveRecord::Base
	
	attr_protected

	cattr_reader :attr_of_interest, :fuzzy_attr, :crisp_attr, :attr

  	# FS generation

  	def self.gen_fs(name, min, max, step)
  		[("#{name}_less_than_#{min-step}").to_sym, [min-step, 1, min, 0]] +
  		Array((min..max).step(step)).flat_map{|head| [("#{name}_about_#{head}").to_sym, [head-step, 0, head, 1, head+step, 0]]} +
  		[("#{name}_more_than_#{max}").to_sym, [max-step, 0, max, 1]]
  	end

	def self.fuzzy_attr
		@@fuzzy_attr ||= {
			#age: [
			#	:young, [25, 1, 40, 0],
			#	:middle_aged, [25, 0, 40, 1, 50, 1, 65, 0],
			#	:old, [50, 0, 65, 1]
			#],
			age: [
				:less_than_40, [40, 1, 45, 0],
				:about_45_50, [40, 0, 45, 1, 50, 1, 55, 0],
				:more_than_55, [50, 0, 55, 1]
			],
			#age: self.gen_fs(:age, 45, 55, 5),
			ea: self.gen_fs(:ea, 550, 1300, 50),
			eka: self.gen_fs(:eka, 1.4, 1.7, 0.1),
			sm_a: self.gen_fs(:sm_a, 50, 60, 5),
			experience: self.gen_fs(:experience, 20, 20, 5),
			difference: [
				:not_significant, [0.2, 1, 0.3, 0],
				:quite_significant, [0.2, 0, 0.3, 1, 0.4, 1, 0.5, 0],
				:significant, [0.4, 0, 0.5, 1, 0.6, 1, 0.7, 0],
				:very_significant, [0.6, 0, 0.7, 1]
			]
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
			profession: [:drill_runner, :loader_operator, :stope_miner, :shaftman, :timberman, :foreman, :lineman]
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

	def self.track_difference data, filter, par1, par2
		partition = @@fuzzy_attr[par1]
		#raise partition.inspect
		track = partition.each_slice(2).each_with_index.map{|fs, i|
			{filter: fs, best_fit: find_best_fit(data, filter + [fs[0]], par2)[0],
				compare: (i==0 ? nil : [partition[i*2-2], partition[i*2-1]]),
				diff: (i==0 ? 0 : fuzzy_compare(data, par2, filter + [fs[0]], filter + [partition[i*2-2]]))}
		}

		track[1..-1].each_with_index.map{|sent, i|
		{dir: sent[:diff][0], speed: [Miner.find_best_fit_fs(:difference, sent[:diff][1])[0], sent[:diff][1]],
			from: track[i][:best_fit], to: sent[:best_fit],
			current: sent[:filter], compare: sent[:compare]}
		}
	end

	# BEGIN This should be in lib

	# Takes membership function m of a fuzzy set (array) and value x.
	# Outputs membership degree.

	def self.build_fs m, x
		logger.debug(m)
		logger.debug(x)
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
   		shrinked = Array(0..(raw.count-1)).map{|i| ((i==0 && raw[i+1][1]!=raw[i][1]) || (i==raw.count-1 && raw[i-1][1]!=raw[i][1]) ||
  			(i>0 && raw[i-1][1]!=raw[i][1]) || (i<raw.count-1 && raw[i+1][1]!=raw[i][1]))}.zip(raw).select{|i, x| i}
  			.map{|_, x| x}.uniq.flatten
  	end 		

  	def self.fuzzy_not a
  		a.each_slice(2).flat_map{|x, mf| [x, 1-mf]}
  	end

  	def self.fuzzy_less_than a
  		#raise a.inspect
  		i = a.each_slice(2).find_index{|_, mf| mf == 1}
  		fuzzy_not(a.first(i*2+2))
  	end

  	def self.fuzzy_greater_than a
  		#raise a.inspect
  		i = a.each_slice(2).to_a.reverse.find_index{|_, mf| mf == 1}
  		fuzzy_not(a.last(i*2+2))
  	end

  	def self.fuzzy_compare data, target_param, filter1, filter2
  		summary1 = find_best_fit(data, filter1, target_param)
  		summary2 = find_best_fit(data, filter2, target_param)
  		if summary1[1] == 0 || summary2[1] == 0
  			logger.debug(filter1.inspect)
  			logger.debug(summary1.inspect)
  			logger.debug(filter2.inspect)
  			logger.debug(summary2.inspect)
  			return [:undefined, 0]
  		end
  		less = summary?(data, filter1, [[target_param, fuzzy_less_than(summary2[0])]]) +
  			summary?(data, filter2, [[target_param, fuzzy_greater_than(summary1[0])]])
  		greater = summary?(data, filter1, [[target_param, fuzzy_greater_than(summary2[0])]]) +
  			summary?(data, filter2, [[target_param, fuzzy_less_than(summary1[0])]])
  		[[:less, less/2.0], [:greater, greater/2.0]].max_by{|_, t| t}
  	end

  	def self.fuzzy_and a, b
  		purify_fs(fs_values(a+b).uniq.sort.map{|x, mf| [x, [build_fs(a, x), build_fs(b, x)].min]})
  	end

  	# Takes set of objects (e.g., miners) and filter (array of linguistic labels),
  	# filters out those who have 0 membership in filter.
  	# Outputs array of elements like [object, membership in filter]

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

   	# 

  	def self.find_best_fit_fs param, x
  		attributes[param].map{|lab| fs = send("get_fs_#{lab}"); [lab, fs, build_fs(fs,x)]}
  			.max_by{|x| x[2]}
  	end

  	# Describing a property sum_param of a subset of objects data chosen by filter filter.

  	# Takes array of objects, filter, a parameter for summarization.
  	# Outputs array [best fit fuzzy set (array), truth value].

  	def self.find_best_fit data, filter, sum_param

  		# Filters out objects we are not interested in.

  		data = query(data, filter).map{|x, _| x}

  		if data.empty?
   			return [0, 0]
  		end

  		# Best fit fuzzy sets of the minimum and maximum values of a property manifested by filtered subset.

  		left = find_best_fit_fs(sum_param, data.min_by{|el| el[sum_param]}[sum_param])
  		right = find_best_fit_fs(sum_param, data.max_by{|el| el[sum_param]}[sum_param])

  		# Finds indexes in fuzzy partitions for left and right fuzzy sets.

  		li = fuzzy_attr[sum_param].find_index(left[0])
  		ri = fuzzy_attr[sum_param].find_index(right[0])

  		# Constructs a new fuzzy set = >=min AND <=max

  		b1 = left[1].each_slice(2).find_index{|_, mf| mf == 1}
  		b2 = right[1].each_slice(2).to_a.reverse.find_index{|_, mf| mf == 1}
  		new_fs = left[1].first(b1*2+2) + right[1].last(b2*2 + 2)

  		fs, truth, level = shrink_fs(data, filter, sum_param, new_fs, summary?(data, filter, [[sum_param, new_fs]]), li, ri, 1)

  		[purify_fs(fs.each_slice(2).to_a), truth]	

  	end

  	def self.shrink_fs data, filter, target_param, cur_fs, truth, li, ri, level

  		# Creates arrays reduced from the left and right

  		left = fuzzy_attr[target_param][li+1]
  		right = fuzzy_attr[target_param][ri+1]
  		reduced_l = fuzzy_and(cur_fs, fuzzy_not(left))
  		reduced_r = fuzzy_and(cur_fs, fuzzy_not(right))

  		return [cur_fs, truth] if reduced_l.empty? || reduced_r.empty?

  		# Truth for left- and right-reduced arrays

		truth_l = summary?(data, filter, [[target_param, reduced_l]])
		truth_r = summary?(data, filter, [[target_param, reduced_r]])

		# Theshold value, if greater than specified, we still can reduce FS

		threshold = 0.8

		# If both reduced FSs give threshold lower than specified, return unreduced array

		return [cur_fs, truth, level] if ((truth_l < threshold && truth_r < threshold) || li == ri)

		# If a reduced FS's truth is greater than threshold, reduce futher

		return shrink_fs(data, filter, target_param, reduced_l, truth_l, li+2, ri, level+1) if truth_r < threshold
		return shrink_fs(data, filter, target_param, reduced_r, truth_r, li, ri-2, level+1) if truth_l < threshold
		[shrink_fs(data, filter, target_param, reduced_l, truth_l, li+2, ri, level+1),
			shrink_fs(data, filter, target_param, reduced_r, truth_r, li, ri-2, level+1)].max_by{|_, _, l| l}

	end

	def self.fs_to_s fs
		adj = [:approximately, :roughly, :around, :about]
		fs = fs.each_slice(2).flat_map{|x, mf|
			[(x.is_a?(Integer) ? x : x.round(2)), mf]
		}
		if fs[1] == 1.0
			return "#{adj[0..1].sample} #{fs[0]} or less"
		end
		if fs[fs.count-1] == 1.0
			return "#{adj[0..1].sample} #{fs[fs.count-2]} or greater"
		end
		if fs.count == 6
			return "#{adj.sample} #{fs[2]}"
		else
			return "#{adj[0..1].sample} between #{fs[2]} and #{fs[4]}"
		end
	end

end
