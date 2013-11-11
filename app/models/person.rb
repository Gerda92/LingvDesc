class Person < ActiveRecord::Base

	set_table_name "people"
	set_primary_key :person_id

	cattr_reader :attr_of_interest, :fuzzy_attr, :crisp_attr, :attr

	def self.attr_of_interest
		@@attr_of_interest ||= [:age, :audio_n, :fr_age, :friends_n,
			:groups_n, :marital_status, :photos_n, :sex, :wall_posts_n, :politics,
			:likes_received_per_year, :posts_per_year, :religion]
	end

	def self.fuzzy_attr
		@@fuzzy_attr ||= {
			age: [
				:young, [25, 1, 40, 0],
				:middle_aged, [25, 0, 40, 1, 50, 1, 65, 0],
				:old, [50, 0, 65, 1]
			],

			friends_n: [
				:have_few_friends, [39, 1, 94, 0],
				:have_moderate_number_of_friends, [39, 0, 94, 1, 180, 0],
				:have_many_friends, [94, 0, 180, 1]
			]
=begin
			,
			groups_n: [
				:member_of_few_groups, [8, 1, 25, 0],
				:member_of_moderate_number_of_groups, [8, 0, 25, 1, 70, 0],
				:member_of_many_groups, [25, 0, 70, 1]
			]
=end
		}
	end

	self.fuzzy_attr.each do |attr, fs|
		fs.each_slice(2) do |name, mf|
			define_method(name.to_s + '?') do
				Person.build_fs mf, send(attr)
			end
		end
	end

	def self.crisp_attr
		@@crisp_attr ||= {
			#marital_status: [:single, :engaged, :married],
			sex: [:m, :f],
			#politics: [:commun, :indiff, :social, :liberal, :conserv],
			#religion: [:east_christ, :west_christ, :islam, :judaism, :atheism]
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
			attrs.map{|attr| row.send(attr.to_s + '?')}.min
		}.reduce(:+) * 1.0)
	end

	def self.most x
  		Person.build_fs [0.3, 0, 0.8, 1], x
  	end

	def self.summary? data, filter, summary
		truth = most(aggregate(data, filter + summary) /
			(filter.empty? ? data.count : aggregate(data, filter))) * 1.0
		truth.nan? ? 0.0 : truth
  	end

  	def self.candidates
  		prod = attributes.values[0]
  		attributes.values[1..-1].each do |params|
  			prod = prod.product([nil] + params).map{|x| x.flatten.select{|x| !x.nil?} }
  		end
  		prod.flat_map {|comb| comb.map{|el| [comb - [el], [el]]}}
  	end

  	# END

	# Scopes

	def self.almaty
	    where(country_id: 'kz', city_id: 1526384).limit(100)
	end

	# Statistics

	def self.median attr, n = Person.count, offset = 0
		medians = Person.order(attr).find(:all, offset: (offset + (n - 1)/2), limit: 2)
			.map{|p| p.send(attr) }
		n.odd? ? medians[0] : (1.0*medians.reduce(:+)/2)
	end

	def self.first_quart attr
		n = Person.count
		median(attr, n/2, 0)
	end

	def self.third_quart attr
		n = Person.count
		median(attr, n/2, (n+1)/2)
	end

	class << self; extend ActiveSupport::Memoizable; self; end.memoize :almaty, :median, :first_quart, :third_quart

end
