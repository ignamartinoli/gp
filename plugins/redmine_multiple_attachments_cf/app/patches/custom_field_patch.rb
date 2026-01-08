module CustomFieldPatch
  def self.included(base)
    base.class_eval do
      def self.available_custom_fields
        super + [MultipleAttachmentCustomField]
      end
    end
  end
end
