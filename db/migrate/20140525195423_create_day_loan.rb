class CreateDayLoan < ActiveRecord::Migration
  def up
  	create_table :day_loans do |t|
  		t.integer :day
  		t.float :ratio
  	end
  end

  def down
  end
end
