class MultipleAttachmentCustomField < CustomField
  def self.name
    I18n.t(:label_multiple_attachment_custom_field)
  end

  def type_name
    'Multiple File Attachment'
  end
end
