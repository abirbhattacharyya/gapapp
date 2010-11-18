class User < ActiveRecord::Base
  has_one :profile, :dependent => :destroy
  has_one :preference, :dependent => :destroy
  has_many :products, :dependent => :destroy
  has_many :wardrobes, :dependent => :destroy

  validates_presence_of :screen_name, :token, :secret
  validates_uniqueness_of   :screen_name, :if => :screen_name

  after_create :register_user_to_fb

  #find the user in the database, first by the facebook user id and if that fails through the email hash
  def self.find_by_fb_user(fb_user)
    User.find_by_fb_uid(fb_user.uid) || User.find_by_email_hash(fb_user.email_hashes)
  end


  def self.create_from_fb_connect(fb_user)
    new_facebooker = User.new(:email => "")
    new_facebooker.screen_name = fb_user.name
    new_facebooker.fb_uid = fb_user.uid.to_i
    new_facebooker.image_url = (fb_user.pic_square.nil? || fb_user.pic_square.strip.blank?) ? "http://static.ak.fbcdn.net/pics/q_silhouette.gif" : fb_user.pic_square
    new_facebooker.location = fb_user.locale
    #We need to save without validations
    new_facebooker.save(false)
    new_facebooker.register_user_to_fb

    #fb_user.setStatus("I have just started using #{root_url} application. It's great!!") if status_updates_allowed?
  end

  #We are going to connect this user object with a facebook id. But only ever one account.
  def link_fb_connect(fb_id)
    unless fb_id.nil?
      #check for existing account
      existing_fb_user = User.find_by_fb_uid(fb_id)

      #unlink the existing account
      unless existing_fb_user.nil?
        existing_fb_user.fb_uid = nil
        existing_fb_user.save(false)
      end

      #link the new one
      self.fb_uid = fb_id
      save(false)
    end
  end

  #The Facebook registers user method is going to send the users email hash and our account id to Facebook
  #We need this so Facebook can find friends on our local application even if they have not connect through connect
  #We hen use the email hash in the database to later identify a user from Facebook with a local user
  def register_user_to_fb
    if email
      users = {:email => email, :account_id => id}
      Facebooker::User.register([users])
      self.email_hash = Facebooker::User.hash_email(email)
      save(false)
    end
  end

  def facebook_user?
    return !fb_uid.nil? && fb_uid.to_i > 0
  end
end
