class Profile < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :name, :message => "^Hey, bussiness name can't be blank"
  validates_presence_of :city, :message => "^Hey, city can't be blank"
  validates_presence_of :state, :message => "^Hey, state can't be blank"
  validates_presence_of :zip, :message => "^Hey, zip can't be blank"
  validates_presence_of :phone, :message => "^Hey, phone can't be blank"
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :message => "^Hey, please enter valid email"

  validate :valid_address
  validate :validate_url

  private

  def valid_address
    if(self.address1 and self.address2)
        self.errors.add(:address1, "^Hey, please enter address line1 or line2") if(self.address1.strip.blank? and self.address2.strip.blank?)
    end
  end

  def validate_url
    response = HTTParty.get(self.web_url ).response
    unless [200,301,302].include? response.code.to_i
      errors.add(:web_url, "^Hey, please enter url in the format of : http://www.mysite.com") unless %w(200 301 302).include?(Profile.status_code(self.web_url))
    end
  end

end
