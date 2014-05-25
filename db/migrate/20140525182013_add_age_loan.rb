class AddAgeLoan < ActiveRecord::Migration
  def up
  	require 'csv'
  	attrs = AgeLoan.column_names - ["id"]
	params = []
	CSV.open('age_loan.csv', 'r').each_with_index do |row, i|
		# logger.debug(row, i)
		if i == 0
			params = row.map{|a| a.to_sym}
			next
		end
	  	AgeLoan.create!(Hash[params.zip(row)])
	end
  end

  def down
  	AgeLoan.delete_all
  end
end
