module PatchActionView
  # This is a cheap but effective hack. I wanted to keep changes to
  # the core effectively nil, unless you knew to add the :order
  # option. Therefore, if you do, this adds a display_order accessor
  # to the errors.order object as a means of simple transport.
  def assign_error_order_to_object(object,order,object_name=nil)
    if object
      class << object.errors
        attr_accessor :display_order
      end

      if order && order.kind_of?(Array)
        object.errors.display_order=order.collect{|attr| attr.to_s}
      elsif order && order.kind_of?(Hash) && order=order.stringify_keys[object_name.to_s]
        object.errors.display_order=order.collect{|attr| attr.to_s}
      end
    end
    return object
  end

  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    if object = options.delete(:object)
      objects = [assign_error_order_to_object(object,options[:order])].flatten
    else
      objects = params.collect {|object_name| assign_error_order_to_object(instance_variable_get("@#{object_name}"),options[:order],object_name) }.compact
    end
    count = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'errorExplanation'
        end
      end
      options[:object_name] ||= params.first
      options[:header_message] = "#{pluralize(count, 'error')} prohibited this #{options[:object_name].to_s.gsub('_', ' ')} from being saved" unless options.include?(:header_message)
      options[:message] ||= 'There were problems with the following fields:' unless options.include?(:message)

      error_messages = objects.map {|object| object.errors.full_messages(object.errors.display_order).map {|msg| content_tag(:li, msg) } }

      contents = ''
      contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
      contents << content_tag(:p, options[:message]) unless options[:message].blank?
      contents << content_tag(:ul, error_messages)
  
      content_tag(:div, contents, html)
    else
      ''
    end
  end
end
