# Please note, this is my first plugin. If this is not the recommended practice 
# for extending the core, let me know, and I will change my code accordingly.
ActiveRecord::Errors.class_eval do
  def full_messages(ordered_keys=nil)
    full_messages = []

    ordered_keys = [] unless ordered_keys

    # First, take the intersection of ordered keys and actual errors.
    ordered_keys &= @errors.keys

    # Then, add whatever was not specified in the order array.
    ordered_keys += @errors.keys-ordered_keys

    ordered_keys.each do |attr|
      @errors[attr].each do |msg|
        next if msg.nil?
        if attr == "base"
          full_messages << msg
        elsif msg =~ /^\^/
          full_messages << msg[1..-1]
        elsif msg.is_a? Proc
          full_messages << msg.call(@base)
        else
          full_messages << @base.class.human_attribute_name(attr) + " " + msg
        end
      end
    end
    full_messages
  end
end
