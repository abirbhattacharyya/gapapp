class CreateWardrobes < ActiveRecord::Migration
  def self.up
    create_table :wardrobes do |t|
      t.integer :user_id
      t.string :gender
      t.integer :qty
      t.integer :total_price
      t.integer :discounted_price
      t.boolean :completed, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :wardrobes
  end
end
