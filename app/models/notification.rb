class Notification < ActionMailer::Base
  default_url_options[:host] = "dealkat.net"

  def sendto(recipient, product, name, message, sent_at = Time.now)
    subject    'Cool info from dealkat'
    #recipients recipient
    bcc recipient
    from       sender_email
    reply_to   "dealkat@dealkat.com"

    body      :product => product, :name => name, :message => message
    sent_on    sent_at
    content_type 'text/html'
  end

  def payment_completed(recipient, data,sent_at = Time.now)
    subject    'Your wardrobe voucher'
    #recipients recipient
    bcc recipient
    from       sender_email
    reply_to   "dealkat@dealkat.com"

    body      data
    sent_on    sent_at
    content_type 'text/html'
    attachment :content_type => "application/pdf",:filename => "GAP_Voucher.pdf",:body => File.read(RAILS_ROOT + "/Voucher.pdf")
  end

  protected

  def sender_email
      "\"Dealkat\" <dealkat@dealkat.com>"
  end
end
