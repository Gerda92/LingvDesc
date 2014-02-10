class AddInitialMiners < ActiveRecord::Migration
  def up
	require 'csv'
	attrs = Miner.column_names - ["id"]
	params = []
	CSV.open('db.csv', 'r').each_with_index do |row, i|
		if i == 0
			params = row.map{|a| a.to_sym}
			next
		end
	  	Miner.create!(Hash[params.zip(row)])
	end
  end

  def down
  	Miner.delete_all
  end
end
