class Wardrobe < ActiveRecord::Base
  belongs_to :user
  has_many :combinations, :dependent => :destroy
  has_one :schedule, :dependent => :destroy

  validates_presence_of :gender, :message => "^Hey, gender can't be blank"
  validates_presence_of :qty, :message => "^Hey, quantity can't be blank"

  def discover?
    (self.total_price.to_i > 0 or self.discounted_price.to_i > 0)
  end

  def gender_name
    ((self.gender.strip.downcase == "women") ? "female" : "male")
  end
end
