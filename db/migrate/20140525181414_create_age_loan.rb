class CreateAgeLoan < ActiveRecord::Migration
  def up
  	create_table :age_loans do |t|
  		t.integer :age
  		t.float :ratio
  	end
  end

  def down
  end
end
