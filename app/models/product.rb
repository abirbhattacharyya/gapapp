class Product < ActiveRecord::Base
  belongs_to :user
  named_scope :names, lambda { |user, gender, dept| { :conditions => ["user_id=? and gender=? and department=?", user, gender, dept] } }
end
