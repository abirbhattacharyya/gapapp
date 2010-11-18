class AddPricesToCombinations < ActiveRecord::Migration
  def self.up
    add_column :combinations, :total_reg_price, :float
    add_column :combinations, :total_min_price, :float
  end

  def self.down
    remove_column :combinations, :total_min_price
    remove_column :combinations, :total_reg_price
  end
end
