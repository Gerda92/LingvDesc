class CreateMiners < ActiveRecord::Migration
  def change
    create_table :miners do |t|
        t.string :name
    	t.string :group
    	t.string :profession
    	t.integer :age
    	t.integer :experience
        t.string :tgroup
    	params = [:ea, :eka, :sm_a, :sm_b, :rl_a, :rl_b, :mp_a, :mp_b, :l_a, :l_b, :ss_a, :ssb, :sp_a, :sp_b,
            :ea_after, :eka_after, :sm_a_after, :sm_b_after, :rl_a_after, :rl_b_after, :mp_a_after, :mp_b_after, :l_a_after, :l_b_after, :ss_a_after, :ssb_after, :sp_a_after, :sp_b_after,
            :p1, :p2, :p3, :p5, :p6, :p8, :noise, :vibration, :tempereature, :humidity, :air_flow]
        params.each{|p|
            t.float p
        }
    end
  end
end
