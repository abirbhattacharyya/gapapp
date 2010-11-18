require 'pdf/writer'
require 'csv'

class ProductsController < ApplicationController
  before_filter :check_login, :except => [:capsule, :send_to, :payments]

  def product_catalog
    @products = current_user.products
    if request.post?
      if !params[:uploaded_file].blank?
        file = params[:uploaded_file]
        FileUtils.mkdir_p "#{RAILS_ROOT}/public/uploads"

        file_path = "#{RAILS_ROOT}/public/uploads/#{Time.now.to_date}_#{file.original_filename}"
        if file_path.match(/(.*?)[.](.*?)/)
          mime_extension = File.mime_type?(file_path)
        else
            flash[:error]="Hey, files in csv format please"
            return
        end

        if mime_extension.eql? "text/comma-separated-values"
            @products.destroy_all

            if !file.local_path.nil?
               FileUtils.copy_file(file.local_path,"#{file_path}")
            else
               File.open("#{file_path}", "wb") { |f| f.write(file.read) }
            end

            @file=File.open(file_path)
            n=0
            CSV::Reader.parse(File.open("#{file_path}", 'rb')) do |row|
                product = Product.new
                product.user = current_user

                error = ""
                if row.size == 8
                    product.department = row[0]
                    product.gender = row[1]
                    product.proportion = row[2]
                    product.name = row[3].to_s
                    product.inventory = row[4]
                    product.image_url = row[5]
                    product.reg_price = row[6].gsub(/[$]/, "").gsub(/[,]/, "").to_f if row[6]
                    product.min_price = row[7].gsub(/[$]/, "").gsub(/[,]/, "").to_f if row[7]

                    product.errors.add_to_base("Hey, regular price must be atleast 1") if product.reg_price < 1
                    if product.image_url and !product.image_url.strip.blank?
                        pic_url = product.image_url + " "
                        if pic_url.match("(.*?)//(.*?)/(.*?) ")
                            site = $2
                            url = "/" + $3
                            ext = url.downcase.reverse[0..url.reverse.index("\.")]

                            if(ext.reverse.to_s.eql?("\.png") or ext.reverse.to_s.eql?("\.jpg") or ext.reverse.to_s.eql?("\.jpeg") or ext.reverse.to_s.eql?("\.gif"))
                                #TODO Nothing
                            else
                                product.errors.add(:image_url ,"^Hey, photo url should be of png, jpg or gif")
                            end
                        end
                    end

                    if(error.blank? and product.errors.empty?)
                        product.save
                        if(product.image_url and !product.image_url.strip.blank?)
                            FileUtils.mkdir_p "#{RAILS_ROOT}/public/products"

                            Net::HTTP.start("#{site}") { |http|
                              resp = http.get("#{url}")
                              open("public/products/#{product.id}#{ext.reverse.to_s}", "wb") { |file|
                                file.write(resp.body)
                               }
                            }
                            product.update_attribute(:image_url, "/products/#{product.id}#{ext.reverse.to_s}")
                        end
                        n=n+1
                        GC.start if n%50==0
                    end
                end
            end
            if n==0
              flash[:notice] = "Uploaded file has the wrong columns. Plz. fix & re-upload"
            else
              flash[:notice]="Uploaded your file!"
              redirect_to root_path
            end
        else
            flash[:error]="Plz. upload a file with the correct format"
        end
      else
        flash[:error]="Hey, please upload csv file" if params[:uploaded_file]
      end
    end
  end

  def wardrobe
    if request.post?
      @wardrobe = Wardrobe.new(params[:wardrobe])
      @wardrobe.user = current_user
      @wardrobe.completed = (params[:s_type].downcase != "discover")
      if @wardrobe.save
        if @wardrobe.completed
          redirect_to combinations_path(@wardrobe)
        else
          redirect_to discover_path(@wardrobe)
        end
      else
        flash[:error] = "Please fill in all the information"
      end
    end
  end

  def combinations
    if params[:id]
      @wardrobe = Wardrobe.find_by_id(params[:id])
      if @wardrobe.nil?
        redirect_to root_path
        return
      elsif Combination.find_by_wardrobe_id(@wardrobe.id)
        redirect_to root_path
        return
      else
        @products = current_user.products.all(:conditions => ["gender=?", @wardrobe.gender_name], :group => "department")
      end
      if request.post?
        products = []
        total_reg_price = 0
        total_min_price = 0
        for product in @products
          products << params["product_#{product.id}"]
          total_reg_price += product.reg_price
          total_min_price += product.min_price
        end
        products = products.compact!
        if products.size.to_i >= @products.size.to_i or products.size.to_i >= @wardrobe.qty.to_i
          Combination.create(:wardrobe_id => @wardrobe.id, :products => (products * ", "), :total_reg_price => total_reg_price, :total_min_price => total_min_price)
          redirect_to schedule_path(@wardrobe)
        else
          flash[:error] = "Please select products for combinations"
        end
      end
    end
  end

  def discover
    if params[:id]
      @wardrobe = Wardrobe.find_by_id(params[:id])
      redirect_to root_path if @wardrobe.nil? or @wardrobe.completed

      if request.post?
        @wardrobe.update_attributes(params[:wardrobe])
        if((@wardrobe.total_price.to_i == 0) and (@wardrobe.discounted_price.to_i == 0))
          flash[:error] = "Please fill in all the information"
        else
          @wardrobe.update_attribute(:completed, true)
          @products = current_user.products.all(:conditions => ["gender=?", @wardrobe.gender_name], :group => "department", :order => "rand()", :limit => @wardrobe.qty)
          products = []
          total_reg_price = 0
          total_min_price = 0
          for product in @products
            product_names = Product.names(product.user_id, product.gender, product.department)
            product_name = product_names[rand(99)%product_names.size]
            products << product_name.id
            total_reg_price += product_name.reg_price
            total_min_price += product_name.min_price
          end
          Combination.create(:wardrobe_id => @wardrobe.id, :products => (products * ", "), :total_reg_price => total_reg_price, :total_min_price => total_min_price)
          flash[:error] = "Updated!"
          redirect_to schedule_path(@wardrobe)
        end
      end
    end
  end

  def generate_combinations
    new_combinations("men")
    new_combinations("women")
    flash[:notice] = "Combinations Generated"
    redirect_to root_path
  end

  def new_combinations(gender)
    @products = current_user.products.all(:conditions => ["gender=?", ((gender.strip.downcase == "women") ? "female" : "male")], :group => "department")
    size = @products.size
    @products.each_with_index do |product1, id1|
        product_names1 = Product.names(product1.user_id, product1.gender, product1.department)
        for name1 in product_names1
          products = []
          total_reg_price = 0
          total_min_price = 0
          @products.each_with_index do |product2, id2|
              if id2 > id1
                product_names2 = Product.names(product2.user_id, product2.gender, product2.department)
                for name2 in product_names2
                  @products.each_with_index do |product3, id3|
                      if id3 > id2
                        product_names3 = Product.names(product3.user_id, product3.gender, product3.department)
                        for name3 in product_names3
                          @products.each_with_index do |product4, id4|
                              if id4 > id3
                                product_names4 = Product.names(product4.user_id, product3.gender, product3.department)
                                for name4 in product_names4
                                  products = [name1.id, name2.id, name3.id, name4.id]
                                  total_reg_price = name1.reg_price + name2.reg_price + name3.reg_price + name4.reg_price
                                  total_min_price = name1.min_price + name2.min_price + name3.min_price + name4.min_price
                                  @wardrobe = Wardrobe.create(:user_id => current_user.id, :gender => gender, :qty => 4, :completed => true)
                                  @combo = Combination.create(:wardrobe_id => @wardrobe.id, :products => (products * ", "), :total_reg_price => total_reg_price, :total_min_price => total_min_price)
                                  @schedule = Schedule.create(:wardrobe_id => @wardrobe.id, :start_date => Date.today)
                                end
                              end
                          end
                          products = [name1.id, name2.id, name3.id]
                          total_reg_price = name1.reg_price + name2.reg_price + name3.reg_price
                          total_min_price = name1.min_price + name2.min_price + name3.min_price
                          @wardrobe = Wardrobe.create(:user_id => current_user.id, :gender => gender, :qty => 3, :completed => true)
                          @combo = Combination.create(:wardrobe_id => @wardrobe.id, :products => (products * ", "), :total_reg_price => total_reg_price, :total_min_price => total_min_price)
                          @schedule = Schedule.create(:wardrobe_id => @wardrobe.id, :start_date => Date.today)
                        end
                      end
                  end
                  products = [name1.id, name2.id]
                  total_reg_price = name1.reg_price + name2.reg_price
                  total_min_price = name1.min_price + name2.min_price
                  @wardrobe = Wardrobe.create(:user_id => current_user.id, :gender => gender, :qty => 2, :completed => true)
                  @combo = Combination.create(:wardrobe_id => @wardrobe.id, :products => (products * ", "), :total_reg_price => total_reg_price, :total_min_price => total_min_price)
                  @schedule = Schedule.create(:wardrobe_id => @wardrobe.id, :start_date => Date.today)
                end
              end
          end
        end
    end
  end

  def schedule
    if params[:id]
      @wardrobe = Wardrobe.find_by_id(params[:id])
      if @wardrobe.nil?
        redirect_to root_path
        return
      elsif Schedule.find_by_wardrobe_id(@wardrobe.id)
        redirect_to root_path
        return
      end
      if request.post?
          s_type = (params[:s_type].strip.downcase)
          if s_type == 'later'
            session[:later] = @wardrobe.id
            flash[:notice] = "You come back soon, you hear!"
            redirect_to root_path
            return
          elsif s_type == 'live'
            Schedule.create(:wardrobe_id => @wardrobe.id, :start_date => Date.today)
            flash[:error] = "Yeah you are live!"
          else
            Schedule.create(:wardrobe_id => @wardrobe.id, :start_date => params[:start_date].to_date)
            flash[:error] = "Scheduled!"
          end
          redirect_to root_path
      end
    end
  end

  def send_to
    @product = Combination.find_by_id(params[:id])
    redirect_to root_path if @product.nil?

    if params[:emails]
        @emails = params[:emails]
        @message = params[:message]
        if check_emails(@emails)
            name = (params[:name].nil? or params[:name].blank?) ? 'Someone' : params[:name]
            recipient = @emails

            Notification.deliver_sendto(recipient,@product,name,params[:message])
            flash[:notice]= "Yeah! Email sent!"
            redirect_to capsule_path(@product.id)
        else
            flash[:error]= "Hey, please enter a valid email address"
        end
    end
  end

  def capsule
    if params[:id]
      @product = Combination.find_by_id(params[:id])
      if @product.nil?
        redirect_to root_path 
        return
      end
      @accepted_offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, "accepted")
      @accepted = (@accepted_offer.nil? ? false: true)
      @counter_offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, "counter")
      @new_price = @counter_offer.price if @counter_offer
      @counter = (@counter_offer ? true : false)
      @last_offer = (@counter_offer ? true : false)
      if request.post?
        @offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, nil)
        if params[:submit_button]
          submit = params[:submit_button].strip.downcase
          if submit == "bid"
            @bid = true
            return
          end
          if submit == "no"
              if @offer
                for offer in Offer.all(:conditions => ["ip=? and combination_id=? and id<=? and counter<>'accepted'", request.remote_ip, @product.id, @offer.id])
                  offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
                end
              end
              if @counter_offer
                @counter_offer.update_attribute(:response, "rejected")
              end
              @counter = false
              flash[:error] = "Hey, sorry it didn't work out."
              return
          elsif submit == "yes"
              if @offer
                for offer in Offer.all(:conditions => ["ip=? and combination_id=? and id<=?", request.remote_ip, @product.id, @offer.id])
                  offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
                end
#                flash[:error] = "You accepted the offer @ $#{@offer.price.ceil} for the wardrobe!"
                flash[:error] = "Cool, the wardrobe is yours for $#{@offer.price.ceil}"
              end
              if @counter_offer
                @counter_offer.update_attribute(:response, "accepted")
#                flash[:error] = "You accepted the offer @ $#{@counter_offer.price.ceil} for the wardrobe!"
                flash[:error] = "Cool, the wardrobe is yours for $#{@counter_offer.price.ceil}"
              end
              @accepted = true
              @accepted_offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, "accepted")
              if @accepted_offer.nil?
                flash[:error] = ""
                redirect_to capsule_path(@product.id)
              end
              return
          end
        end
        price = params[:price]
#        product = Product.first(:conditions => ["description=?", @product.product_name])
        min_price = @product.total_min_price
        reg_price = @product.total_reg_price
        if price and price.strip.blank?
#          flash[:error] = "Hey, say your price"
          @error = true
        elsif price.to_i <= 0
          flash[:error] = "Hey you can't get something for nothing"
        else
          @offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, nil)
          if @offer
            if price.to_f > @offer.price
              @offer.update_attribute(:price, price)
              @offer.update_attribute(:counter, @offer.counter+1)
            else
              flash[:error] = "Your offer=$#{price.to_i} is rejected for the wardrobe!"
              for offer in Offer.all(:conditions => ["ip=? and combination_id=? and id<=?", request.remote_ip, @product.id, @offer.id])
                  offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
              end
              @offer.update_attribute(:response, "rejected")
              return
            end
          else
            @offer = Offer.new(:ip => request.remote_ip, :combination_id => @product.id, :price => price, :counter => 1)
            @offer.save
          end
          percent = 0.40

          if(price.to_i >= min_price)
              @accepted = true
          elsif(price.to_i >= (percent*reg_price).ceil)
              Offer.create(:ip => request.remote_ip, :combination_id => @product.id, :price => min_price.ceil, :response => "counter", :counter => 1)
              @counter_offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, "counter")
              if @counter_offer
                flash[:notice] = "Hey, the best we can do is $#{@counter_offer.price.ceil}. Deal?"
                @new_price = @counter_offer.price.ceil
                @last_offer = true
              end
              @counter = true
          else
#              flash[:error] = "Your offer=$#{price.to_i} is rejected for the wardrobe!"
              flash[:error] = "Hey, the regular wardrobe price=$#{reg_price.ceil}. Make another offer?"
              for offer in Offer.all(:conditions => ["ip=? and combination_id=? and id<=?", request.remote_ip, @product.id, @offer.id])
                  offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
              end
              @offer.update_attribute(:response, "rejected")
              return
          end

          if @accepted == true
            for offer in Offer.all(:conditions => ["ip=? and combination_id=? and id<=?", request.remote_ip, @product.id, @offer.id])
                offer.update_attribute(:response, "expired") if offer.response != "paid" and offer.response != "accepted"
            end
            if(price.to_i >= reg_price)
              @offer.update_attribute(:price, (reg_price*0.90))
            end
            if @offer.counter > 1
              @offer.update_attribute(:response, "accepted")
            elsif @counter_offer
              @counter_offer.update_attribute(:response, "accepted")
            else
              @offer.update_attribute(:response, "accepted")
            end
            @accepted_offer = Offer.find_last_by_ip_and_combination_id_and_response(request.remote_ip, @product.id, "accepted")
            if(price.to_i >= reg_price)
              msg = "Hey, don't overspend. The wardrobe is yours at a discount for $#{@accepted_offer.price.ceil}"
            else
              msg = "Your offer=$#{@accepted_offer.price.ceil} is accepted for the wardrobe!"
            end
            flash[:error] = msg
          end
        end
      end
    else
      redirect_to root_path
    end
  end

  def payments
    if params[:id]
      @offer = Offer.find_by_id(params[:id])
      @month =Date.today.month
      if request.post?
          if params[:payment]
              @payment = Payment.new(params[:payment])
              @payment.offer = @offer
              if @payment.cc_expiry_y == Date.today.year
                @payment.cc_expiry_m = @payment.cc_expiry_m1
              else
                @payment.cc_expiry_m = @payment.cc_expiry_m2
              end
              @month = @payment.cc_expiry_m
              if @payment.save
                @offer.update_attribute(:response, "paid")
                output= render_to_string :partial => "partials/accept_letter", :object => @payment
                data= render_to_string :partial => "partials/payment_mailer", :object => @payment

                pdf = PDF::Writer.new
                pdf.text output
                pdf.save_as("Voucher.pdf")
                Notification.deliver_payment_completed(@payment.email, data)
                flash[:notice] = "Cool you just won an exclusive deal on a cool wardrobe!"
                redirect_to winners_path
              else
                flash[:error] = "Please fill in all the information"
              end
          end
      end
    end
  end
end
