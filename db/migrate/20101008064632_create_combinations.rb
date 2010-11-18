class CreateCombinations < ActiveRecord::Migration
  def self.up
    create_table :combinations do |t|
      t.integer :wardrobe_id
      t.string :products

      t.timestamps
    end
  end

  def self.down
    drop_table :combinations
  end
end
