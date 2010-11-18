require 'rubygems'

class HomeController < ApplicationController
  before_filter :check_login, :except => [:index, :faqs, :say_your_price, :wardrobes, :winners]
  skip_before_filter :verify_authenticity_token

  def index
    if logged_in?
      if current_user.user_type.nil?
        render :template => "/home/share"
      elsif current_user.profile.nil?
        render :template => "/users/profile"
      elsif current_user.preference.nil?
        render :template => "/users/preferences"
      elsif current_user.products.size <= 0
        render :template => "/products/product_catalog"
      else
        @notifications = [["profile", current_user.profile.created_at], ["prices", current_user.products.last.created_at], ["Twitter Preferences", current_user.preference.created_at]]
        @notifications.sort!{|n1, n2| n2[1] <=> n1[1]}

        @wardrobe = current_user.wardrobes.last
        if @wardrobe.nil?
          render :template => "/home/notifications" 
          return
        elsif session[:later] and session[:later] == @wardrobe.id
          render :template => "/home/notifications"
          return
        end
        if @wardrobe.completed == true
          if @wardrobe.discover?
              if Schedule.find_by_wardrobe_id(@wardrobe.id)
                render :template => "/home/notifications"
              else
                redirect_to schedule_path(@wardrobe)
              end
          else
              if Combination.find_by_wardrobe_id(@wardrobe.id)
                if Schedule.find_by_wardrobe_id(@wardrobe.id)
                  render :template => "/home/notifications"
                else
                  redirect_to schedule_path(@wardrobe)
                end
              else
                redirect_to combinations_path(@wardrobe)
              end
          end
        else
          redirect_to discover_path(@wardrobe)
        end
      end
#    else
#      render :template => "/users/login"
    end
  end

  def notifications
    @notifications = [["profile", current_user.profile.created_at], ["prices", current_user.products.last.created_at], ["Twitter Preferences", current_user.preference.created_at]]
    @notifications.sort!{|n1, n2| n2[1] <=> n1[1]}
  end

 def analytics
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    @size = 7
    @per_page = 1
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    @titleX = "Time Period"
    @titleY = "#"
    @colors = []

    case @page
      when 1
        @title = "# Came to SYP Capsule"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 2
        @title = "# Started Negotiating"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 3
        @title = "# Reached Pricing Agreement"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and offers.response='accepted' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and offers.response='accepted' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 4
        @title = "# Completed a Sale"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and offers.response='paid' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and offers.response='paid' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 5
        @title = "$ Completed Sales"
        @titleY = "$"
        @offer_today = Offer.first(:select => "SUM(price) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and offers.response='paid' and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(price) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and offers.response='paid' and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
      when 6
        @title = "$ Sales By Wardrobe (Men)"
        @titleY = "$"
        @offers = Offer.all(:joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and wardrobes.gender like 'men' and offers.response='paid'", :order => "offers.price DESC", :limit => 3)
        @chart_data1 = []
        @offers.each_with_index do |offer, i|
          @chart_data1 << ["Wardrobe #{i+1}", offer.price.to_i]
        end
      when 7
        @title = "$ Sales By Wardrobe (Women)"
        @titleY = "$"
        @colors << '#FE3496'
        @offers = Offer.all(:joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and wardrobes.gender like 'women' and offers.response='paid'", :order => "offers.price DESC", :limit => 3)
        @chart_data1 = []
        @offers.each_with_index do |offer, i|
          @chart_data1 << ["Wardrobe #{i+1}", offer.price.to_i]
        end
      else
        @title = "# Came to SYP Capsule"
        @offer_today = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today}'")
        @offer_yesterday = Offer.first(:select => "SUM(counter) as total", :joins => "INNER JOIN combinations ON offers.combination_id=combinations.id INNER JOIN wardrobes ON combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id} and Date(offers.updated_at)='#{Date.today - 1.day}'")
        @chart_data1 = [["Yesterday", @offer_yesterday.total.to_i], ["Today", @offer_today.total.to_i]]
    end
  end


  def my_wardrobes
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    if logged_in? and current_user.user_type
      combinations = Combination.first(:select => "count(combinations.id) as size", :joins => "INNER JOIN wardrobes on combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id}")
    else
      combinations = Combination.first(:select => "count(combinations.id) as size")
    end
    @size = combinations.size.to_i
    @per_page = 1
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    if logged_in? and current_user.user_type
      @combinations = Combination.all(:joins => "INNER JOIN wardrobes on combinations.wardrobe_id=wardrobes.id and wardrobes.user_id=#{current_user.id}", :order => "combinations.total_reg_price ASC", :limit => "#{@per_page*(@page - 1)}, #{@per_page}")
    else
      @combinations = Combination.all(:limit => "#{@per_page*(@page - 1)}, #{@per_page}")
    end
  end

  def say_your_price
    if logged_in? and current_user.user_type
      redirect_to root_path
    end
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    combinations = Combination.first(:select => "count(combinations.id) as size")
    @size = combinations.size.to_i
    @per_page = 1
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    @combinations = Combination.all(:limit => "#{@per_page*(@page - 1)}, #{@per_page}")
  end

  def wardrobes
    if request.post?
      @gender = params[:gender].strip.downcase
    else
      @gender = 'women'
    end
    if request.post?
      @page = params[:page].to_i
    else
      @page = 1
    end
    combinations = Combination.first(:select => "COUNT(combinations.id) as size", :joins => "INNER JOIN wardrobes on combinations.wardrobe_id=wardrobes.id and wardrobes.gender='#{@gender}'")
    @size = combinations.size.to_i
    @per_page = 10
    @post_pages = (@size.to_f/@per_page).ceil;
    @page =1 if @page.to_i<=0 or @page.to_i > @post_pages
    @combinations = Combination.all(:joins => "INNER JOIN wardrobes on combinations.wardrobe_id=wardrobes.id and wardrobes.gender='#{@gender}'", :order => "id desc", :limit => "#{@per_page*(@page - 1)}, #{@per_page}")
  end

  def winners
    @payments = Payment.all(:order => "id desc", :limit => 100)
  end
end
