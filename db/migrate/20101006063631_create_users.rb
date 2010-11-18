class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string    :screen_name
      t.string    :image_url
      t.string    :location

      t.string    :token
      t.string    :secret

			t.string		:fb_uid
			t.string		:email, :limit => 100
			t.string		:email_hash

      t.string    :remember_token
      t.string    :remember_token_expires_at
      t.timestamps
      t.string    :user_type
    end
  end

  def self.down
    drop_table :users
  end
end
