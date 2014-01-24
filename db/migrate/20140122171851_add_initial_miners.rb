class AddInitialMiners < ActiveRecord::Migration
  def up
	require 'csv'
	attrs = Miner.column_names - ["id"]
	CSV.open('db.csv', 'r').each do |row|
	  Miner.create!(Hash[attrs.zip(row)])
	end
  end

  def down
  	Miner.delete_all
  end
end
