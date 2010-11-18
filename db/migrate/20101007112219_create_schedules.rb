class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.integer :wardrobe_id
      t.date :start_date

      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end
