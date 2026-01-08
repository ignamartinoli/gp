module RedmineHideCfAttachments
  module IssuePatch
    def self.included(base)
      base.class_eval do
        def visible_attachments_excluding_custom_fields
          attachments.reject do |attachment|
            attachment.container_type == 'CustomValue'
          end
        end
      end
    end
  end
end
