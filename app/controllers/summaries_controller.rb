class SummariesController < ApplicationController

  def index
    #raise FuzzySet.new.make_fs.inspect
    #raise Miner.gen_fs(0, 10, 2).inspect
    #raise Miner.and(Miner.and([1, 1], Miner.not([4, 0, 5, 1])), Miner.not([1, 1, 2, 0])).inspect
    filters = Miner.gen_filters([:group, :profession])
    #raise filters.inspect
    #raise Miner.find_best_fit(Miner.all, [:control, :stope_miner], :emg_a).inspect
    @candidates = filters.map{|filter| [filter] + Miner.find_best_fit(Miner.all, filter, :emg_a)}
    #raise @candidates.inspect
    @sample = Miner.all
    @candidates = @candidates.select{|_,_,t| t > 0}.sort {|a, b| b[2] <=> a[2]}
    #raise @candidates.inspect
  end

  def sum
    #@candidates = [[[:old, :f], [:have_few_friends]]]#Person.candidates
    @candidates = Person.candidates
  	@sample = Person.all
  	@candidates = @candidates.map do |filter, summarizer|
      [filter, summarizer, Person.summary?(@sample, filter, summarizer)]
    end.select{|f, s, t| t > 0}.sort {|a, b| b[2] <=> a[2]}
  end

end
