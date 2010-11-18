class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.integer :user_id
      t.string :department
      t.string :gender
      t.string :proportion
      t.string :name
      t.integer :inventory
      t.string :image_url
      t.float :reg_price
      t.float :min_price
      t.integer :qty, :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
