class CreateMiners < ActiveRecord::Migration
  def change
    create_table :miners do |t|
    	t.string :group
    	t.integer :age
    	t.string :profession
    	t.float :emg_a
    	t.float :emg_ka
    end
  end
end
