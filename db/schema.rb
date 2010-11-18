# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101009113336) do

  create_table "combinations", :force => true do |t|
    t.integer  "wardrobe_id"
    t.string   "products"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "total_reg_price"
    t.float    "total_min_price"
  end

  create_table "offers", :force => true do |t|
    t.string   "ip"
    t.string   "response"
    t.integer  "combination_id"
    t.float    "price"
    t.integer  "counter",        :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer  "offer_id"
    t.string   "name"
    t.string   "cc_no"
    t.integer  "cc_expiry_m"
    t.integer  "cc_expiry_y"
    t.string   "email"
    t.string   "screen_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.integer  "user_id"
    t.integer  "daily_updates"
    t.boolean  "daily_anouncement"
    t.boolean  "price_change"
    t.boolean  "random_user"
    t.boolean  "completed_negotiations"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", :force => true do |t|
    t.integer  "user_id"
    t.string   "department"
    t.string   "gender"
    t.string   "proportion"
    t.string   "name"
    t.integer  "inventory"
    t.string   "image_url"
    t.float    "reg_price"
    t.float    "min_price"
    t.integer  "qty",        :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "web_url"
    t.text     "address1"
    t.text     "address2"
    t.string   "city"
    t.string   "state"
    t.integer  "zip"
    t.string   "phone"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schedules", :force => true do |t|
    t.integer  "wardrobe_id"
    t.date     "start_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "screen_name"
    t.string   "image_url"
    t.string   "location"
    t.string   "token"
    t.string   "secret"
    t.string   "fb_uid"
    t.string   "email",                     :limit => 100
    t.string   "email_hash"
    t.string   "remember_token"
    t.string   "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  create_table "wardrobes", :force => true do |t|
    t.integer  "user_id"
    t.string   "gender"
    t.integer  "qty"
    t.integer  "total_price"
    t.integer  "discounted_price"
    t.boolean  "completed",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
