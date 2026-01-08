# frozen_string_literal: true
require_dependency 'attachments_helper'

module RedmineMultipleAttachmentsCf
  module Patches
    module AttachmentsHelperPatch
      def attachments_to_show(container)
        list = super
        return list unless container.is_a?(Issue)

        # IDs referenciados por CUALQUIER CF de tipo multiple_attachment en este issue
        cf_ids = container.custom_field_values.select { |cv|
          fmt = cv.custom_field.try(:format)
          fmt && fmt.name == 'multiple_attachment'
        }.flat_map { |cv|
          cv.value.to_s.split(',').map(&:strip).reject(&:blank?)
        }

        return list if cf_ids.empty?
        list.reject { |att| cf_ids.include?(att.id.to_s) }
      end
    end
  end
end

unless AttachmentsHelper < RedmineMultipleAttachmentsCf::Patches::AttachmentsHelperPatch
  AttachmentsHelper.prepend RedmineMultipleAttachmentsCf::Patches::AttachmentsHelperPatch
end
