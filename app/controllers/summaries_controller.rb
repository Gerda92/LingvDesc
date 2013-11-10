class SummariesController < ApplicationController
  def index
  	#young = ->(x) { People.build_fs [25, 1, 40, 0], x }
  	#raise young.inspect
  	raise Person.n(:age).inspect
  	@sample = Person.almaty
  	@filter = [:middle_aged]
  	@summary = [:single]
  	#raise @sample.map{|p| p.single? }.inspect
  	@truth = Person.summary?(@sample, @filter, @summary)
  end

end
