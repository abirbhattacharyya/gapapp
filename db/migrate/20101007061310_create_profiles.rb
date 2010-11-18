class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.integer :user_id
      t.string :name
      t.string :web_url
      t.text :address1
      t.text :address2
      t.string :city
      t.string :state
      t.integer :zip
      t.string :phone
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end
