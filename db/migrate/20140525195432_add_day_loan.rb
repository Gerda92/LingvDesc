class AddDayLoan < ActiveRecord::Migration
  def up
  	require 'csv'
  	attrs = DayLoan.column_names - ["id"]
	params = []
	CSV.open('day_loan.csv', 'r').each_with_index do |row, i|
		# logger.debug(row, i)
		if i == 0
			params = row.map{|a| a.to_sym}
			next
		end
	  	DayLoan.create!(Hash[params.zip(row)])
	end
  end

  def down
  	DayLoan.delete_all
  end
end
