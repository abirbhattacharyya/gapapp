# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'open-uri'
require 'json'
require 'hpricot'
require "httparty"
require "calendar_date_select"

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include AuthenticatedSystem
  include ApplicationHelper

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'a6f9978de73ca9fd397297825de7084d'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  before_filter :set_facebook_session
  helper_method :facebook_session

  def check_login
    unless logged_in?
      flash[:notice] = "Please login first"
      redirect_to root_path
    else
      if current_user.facebook_user?
        begin
          facebook_session.user.name
        rescue Facebooker::Session::SessionExpired
          flash[:notice] = "Your Facebook Session has expired. Please login again"
          logout_killing_session!
        end
      end
    end
  end

  def check_emails(emails)
    return false if emails.blank?
    return false if emails.gsub(',','').blank?
    emails.split(',').each do |email|
        unless email.strip =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/
          return false
        end
    end
    return true
  end
end
