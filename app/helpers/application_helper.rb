# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include GoogleVisualization

  def oauth_callback
    "http://184.73.255.153/callback"
  end

  def oauth_consumer
    # The readkey and readsecret below are the values you get during registration
    OAuth::Consumer.new("j6TMRlaFQ6fMoGEqhTNag",
    "IfSnfQu3PUC4ID7OzyZTv3zCRDgjmcVdk4m03oHjEI",
    { :site=>"http://twitter.com" })
  end

  def facebook_session
    session[:facebook_session]
  end

  def facebook_user
    (session[:facebook_session] && session[:facebook_session].session_key) ? session[:facebook_session].user : nil
  end

  def status_updates_allowed?
    if facebook_session
      res = facebook_session.fql_query("select publish_stream from permissions where uid == #{facebook_session.user.uid}")
      if res.join =~ /publish_stream1/
        return true
      else
        return false
      end
    else
      return false
    end
  end
end
