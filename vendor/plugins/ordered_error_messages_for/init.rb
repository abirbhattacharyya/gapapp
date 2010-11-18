unless ActionView::Base.respond_to?(:assign_error_order_to_object)
  require 'patch_active_record'
  ActionView::Base.send(:include, PatchActionView)
end
