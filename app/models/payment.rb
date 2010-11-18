class Payment < ActiveRecord::Base
  belongs_to :offer

  validates_presence_of :name, :message => "^Hey, name can't be blank"
  validates_presence_of :screen_name, :message => "^Hey, twitter id can't be blank"
  validates_presence_of :cc_no, :message => "^Hey, credit card# can't be blank"
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :message => "^Hey, please enter valid email"

  attr_accessor :cc_expiry_m1, :cc_expiry_m2
end
