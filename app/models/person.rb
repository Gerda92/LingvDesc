class Person < ActiveRecord::Base

	set_table_name "profiles_anonymized"
	set_primary_key :person_id

	cattr_reader :attr_of_interest, :fuzzy_attr, :crisp_attr

	def self.attr_of_interest
		@@attr_of_interest ||= [:age, :audio_n, :fr_age, :fr_high_education_percent, :friends_n,
			:groups_n, :marital_status, :photos_n, :sex, :wall_posts_n, :politics,
			:likes_received_per_year, :posts_per_year, :religion]
	end

	def self.fuzzy_attr
		@@fuzzy_attr ||= {
			age: [
				:young, [25, 1, 40, 0],
				:middle_aged, [25, 0, 40, 1, 50, 1, 65, 0],
				:old, [50, 0, 65, 1]
			]
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
			marital_status: [:single, :engaged, :married]
		}
	end

	self.crisp_attr.each do |attr, val|
		val.each do |name|
			define_method(name.to_s + '?') do
				send(attr) == name.to_s ? 1 : 0
			end
		end
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
		most(aggregate(data, filter + summary) / aggregate(data, filter))
  	end

  	# END

	# Scopes

	def self.complete
		cond = attr_of_interest.join(' IS NOT NULL AND ') + ' IS NOT NULL'
	    find(:all, conditions: cond, limit: 100)
	end

	def self.almaty
		cond = attr_of_interest.join(' IS NOT NULL AND ') + ' IS NOT NULL'
	    where(country_id: 'kz', city_id: 1526384).find(:all, conditions: cond, offset: 10, limit: 100)
	end

	# Statistics

	def self.min attr
		Person.minimum(attr)
	end

	def self.ave attr
		Person.average(attr)
	end

	def self.max attr
		Person.maximum(attr)
	end

	def self.n attr
		Person.find(:all, conditions: (attr.to_s + ' IS NOT NULL')).count
	end

	def self.median attr
		Person.order(attr).find(:all, conditions: (attr.to_s + ' IS NOT NULL'), offset: (n/2), limit:1)
	end

	class << self; extend ActiveSupport::Memoizable; self; end.memoize :almaty, :min, :ave, :max, :n

end
