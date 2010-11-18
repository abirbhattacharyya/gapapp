class CreateOffers < ActiveRecord::Migration
  def self.up
    create_table :offers do |t|
      t.string :ip
      t.string :response
      t.integer :combination_id
      t.float :price
      t.integer :counter, :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :offers
  end
end
