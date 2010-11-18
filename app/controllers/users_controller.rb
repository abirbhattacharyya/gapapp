class UsersController < ApplicationController
  before_filter :check_login, :except => [:biz, :login, :create, :callback, :link_user_accounts, :destroy]

  def biz
    if logged_in?
      current_user.update_attribute("user_type", "business") if current_user.user_type.nil?
      redirect_to root_path
    else
      store_location
      if request.post?
        store_location
        redirect_to twitter_login_path
      end
    end
  end

  def login
    redirect_to root_path
  end

  def create
#    @user = User.last
#    if @user
#      session[:user_id] = @user.id
#      redirect_to root_path
#      return
#    end

    @request_token = oauth_consumer.get_request_token( :oauth_callback => oauth_callback )
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    # Send to twitter.com to authorize
    redirect_to @request_token.authorize_url
    return
  end

  def callback
    if params[:denied]
      redirect_to root_path
      return
    end
    @request_token = OAuth::RequestToken.new(oauth_consumer,session[:request_token],session[:request_token_secret])
    @access_token = @request_token.get_access_token( :oauth_verifier => params[:oauth_verifier])
    @response = oauth_consumer.request(:get, '/account/verify_credentials.json',@access_token, { :scheme => :query_string })
    case @response
      when Net::HTTPSuccess
        user_info = JSON.parse(@response.body)
        unless user_info['screen_name']
          flash[:notice] = "Authentication failed"
          redirect_to root_path
          return
        end
        # We have an authorized user, save the information to the database.
        if User.find_by_screen_name(user_info['screen_name'])
          @user = User.find_by_screen_name(user_info['screen_name'])
          @user.update_attribute("token",@access_token.token)
          @user.update_attribute("secret",@access_token.secret)
          @xml_data = open("http://twitter.com/users/show/#{user_info['screen_name']}.xml").read
          @data = Hpricot::XML(@xml_data)
          (@data/:user).each do |status|
              @user.update_attribute(:location, (status.at('location').innerHTML)) if status.at('location')
              @user.update_attribute(:image_url, (status.at('profile_image_url').innerHTML)) if status.at('profile_image_url')
          end
        else
          @user = User.new
          @user.screen_name = user_info['screen_name']
          @user.token = @access_token.token
          @user.secret = @access_token.secret
          @xml_data = open("http://twitter.com/users/show/#{user_info['screen_name']}.xml").read
          @data = Hpricot::XML(@xml_data)
          (@data/:user).each do |status|
              @user.location = (status.at('location').innerHTML) if status.at('location')
              @user.image_url = (status.at('profile_image_url').innerHTML) if status.at('profile_image_url')
          end
          @user.save!
        end
#        @user.update_attribute("user_type", "consumer") if @user.user_type.nil?
        session[:user_id] = @user.id
        # Redirect to the show page
        redirect_back_or_default('/')
    else
      RAILS_DEFAULT_LOGGER.error "Failed to get user info via OAuth"
      # The user might have rejected this application. Or there was some other error during the request.
      flash[:notice] = "Authentication failed"
      redirect_to root_path
      return
    end
  end

  def link_user_accounts
    if current_user.nil?
      #register with fb
      User.create_from_fb_connect(facebook_session.user)
    else
      #connect accounts
      current_user.link_fb_connect(facebook_session.user.id) unless current_user.fb_uid == facebook_session.user.id
    end
    redirect_back_or_default('/')
#    redirect_to root_path
  end

  def profile
    if current_user.profile
      @user_profile = current_user.profile
    end

    if request.post?
        @user_profile = Profile.new(params[:user_profile])
        @profile = Profile.new(params[:user_profile])
        @profile.user = current_user

        if @profile.valid? and @profile.errors.empty?
          if current_user.profile
            current_user.profile.delete if current_user.profile
            flash[:notice] = "Profile Updated!"
          else
            flash[:notice] = "Thanks for entering your profile. Ready to create your campaigns?"
          end
          @profile.save
          redirect_to root_path
        else
          flash[:error] = "Please enter your profile information"
        end
    end
  end

  def preferences
    @preference = current_user.preference
    if request.post?
      if current_user.preference
        if current_user.preference.update_attributes(params[:preference])
          flash[:notice] = "Updated your twitter preferences"
          redirect_to root_path
        else
          flash[:error] = "Plz. select 1 or more tweet actions"
        end
      else
        @preference = Preference.new(params[:preference])
        @preference.user = current_user
        if @preference.save
          flash[:notice] = "Updated your twitter preferences"
          redirect_to root_path
        else
          flash[:error] = "Plz. select 1 or more tweet actions"
        end
      end
    end
  end

  def destroy
    logout_killing_session!
    session[:user_id] = nil
    session[:facebook_session] = nil
    flash[:notice] = "Logged out! See you later!"
    redirect_back_or_default('/')
  end
end
