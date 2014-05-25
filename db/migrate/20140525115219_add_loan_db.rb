class AddLoanDb < ActiveRecord::Migration
  def up
  	require 'csv'
  	attrs = Loan.column_names - ["id"]
	params = []
	CSV.open('loan.csv', 'r').each_with_index do |row, i|
		# logger.debug(row, i)
		if i == 0
			params = row.map{|a| a.to_sym}
			next
		end
	  	Loan.create!(Hash[params.zip(row)])
	end
  end

  def down
  	Loan.delete_all
  end
end