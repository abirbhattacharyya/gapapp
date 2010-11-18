class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.references :user

      t.integer :daily_updates
      t.boolean :daily_anouncement
      t.boolean :price_change
      t.boolean :random_user
      t.boolean :completed_negotiations

      t.timestamps
    end
  end

  def self.down
    drop_table :preferences
  end
end
