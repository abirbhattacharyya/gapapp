class Preference < ActiveRecord::Base
  belongs_to :user

  validate :one_option

  protected

  def one_option
    if self.daily_anouncement == false and self.price_change == false and self.random_user == false and self.completed_negotiations == false
      errors.add_to_base("Hey, please select atleast one option")
    end
  end
end
