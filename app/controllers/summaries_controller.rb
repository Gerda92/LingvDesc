class SummariesController < ApplicationController

  def index
    #raise FuzzySet.new.make_fs.inspect
    #raise Miner.gen_fs(0, 10, 2).inspect
    #raise Miner.and(Miner.and([1, 1], Miner.not([4, 0, 5, 1])), Miner.not([1, 1, 2, 0])).inspect
    filters = Miner.gen_filters([:group, :profession])
    compare_group = [:loader_operator]
    compare = Miner.find_best_fit(Miner.all, compare_group, :ea)[0]
    #raise filters.inspect
    #raise Miner.find_best_fit(Miner.all, [:control, :stope_miner], :emg_a).inspect
    @candidates = filters.map{|filter|
      logger.debug filter.inspect
      summary2 = Miner.find_best_fit(Miner.all, filter, :ea)
      #logger.debug Miner.fuzzy_compare(Miner.all, :emg_a, compare_group, filter).inspect
      [filter] + summary2
    }
    @diff = filters.map{|filter|
      [compare_group] + [filter] + Miner.fuzzy_compare(Miner.all, :ea, compare_group, filter)
    }
    
    @sample = Miner.all
    @candidates = @candidates.select{|_,_,t| t > 0}.sort {|a, b| b[2] <=> a[2]}
    @diff = @diff.select{|_,_,_,t| t > 0}.sort {|a, b| b[3] <=> a[3]}
    #raise @candidates.inspect
  end

  def relationship
    #raise Miner.track_difference(Miner.where('experience > 0'), [:main], :experience, :sm_a).inspect
    @dep = :age
    @tar = :eka
    @track = Miner.track_difference(Miner.all, [:main], @dep, @tar)
  end

  def difference
    #raise Miner.fuzzy_attr.inspect
    filters = Miner.gen_filters([:profession])
    @target = [:stope_miner]
    par = :eka
    @diff = @target.product(filters).map{|filter, compare|
        [compare] + Miner.fuzzy_compare(Miner.all, par, [filter], compare)
      }.map{|compare, dir, sign| [compare, dir, Miner.find_best_fit_fs(:difference, sign)[0]]}
    # raise @diff.inspect
    @ranking = filters.map{|filter| [filter[0], @diff.select{|_,_,f,d| f[0] == filter[0]}.count]}
      .sort{|a, b| b[1] <=> a[1]}.map{|f,_| f}
    
  end

  def difference_table
    #raise Miner.fuzzy_attr.inspect
    filters = Miner.gen_filters([:profession])
    params = [:ea]
    @diff = params.flat_map{|par|
        filters.product(filters).map{|filter, compare|
        [par] + [compare] + [filter] + Miner.fuzzy_compare(Miner.all, par, compare, filter)
      }.select{|_,_,_,d,_| d == :greater}
    }
    @diff = @diff.select{|_,_,_,_,t| t > 0}.sort {|a, b| b[4] <=> a[4]}
  end

end
