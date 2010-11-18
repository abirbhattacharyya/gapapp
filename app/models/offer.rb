class Offer < ActiveRecord::Base
  belongs_to :combination
  has_many :payments, :dependent => :destroy

  delegate :product_name, :to => :combination
end
