class SummariesController < ApplicationController

  def index
    #@candidates = [[[:old, :f], [:have_few_friends]]]#Person.candidates
    @candidates = Person.candidates
  	@sample = Person.all
  	@candidates = @candidates.map do |filter, summarizer|
      [filter, summarizer, Person.summary?(@sample, filter, summarizer)]
    end.select{|f, s, t| t > 0}.sort {|a, b| b[2] <=> a[2]}
  end

end
