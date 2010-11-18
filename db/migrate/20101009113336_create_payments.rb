class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer :offer_id
      t.string :name
      t.string :cc_no
      t.integer :cc_expiry_m
      t.integer :cc_expiry_y
      t.string :email
      t.string :screen_name

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
