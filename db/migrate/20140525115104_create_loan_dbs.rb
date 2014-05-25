class CreateLoanDbs < ActiveRecord::Migration
  def change
  	create_table :loans do |t|
  		t.integer :age
  		t.string :job
  		t.string :education
  		t.string :marital
  		t.string :default
  		t.string :housing
  		t.string :loan
  		t.string :y
  	end
  end
end

