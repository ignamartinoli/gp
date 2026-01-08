# app/patches/issues_controller_patch.rb
module RedmineMultipleAttachmentsCf
  module Patches
    module IssuesControllerPatch
      ALLOWED_EXTS  = %w[.pdf .doc .docx .zip .rar].freeze
      ALLOWED_MIMES = %w[
        application/pdf
        application/msword
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
      ].freeze
      MAX_FILES = 30

      def self.prepended(base)
        if base.respond_to?(:prepend_before_action)
          base.prepend_before_action :rmacf_prepare_multi_attachments_cf, only: [:create, :update]
        else
          base.before_action :rmacf_prepare_multi_attachments_cf, only: [:create, :update]
        end
        base.after_action :rmacf_attach_after_save, only: [:create, :update]
      end

      private

      def rmacf_prepare_multi_attachments_cf
        Rails.logger.info "[RMA-CF] prepare: keys=#{params.keys.inspect}"

        @rmacf_created_attachment_ids_by_cf = {}
        @rmacf_removed_attachment_ids_by_cf = {}

        macf = params[:multiple_attachments_cf] || {}
        rem  = params[:multiple_attachments_cf_remove] || {}

        params[:issue] ||= {}
        params[:issue][:custom_field_values] ||= {}

        macf.each do |cf_id, files|
          files = Array(files).compact

          # cantidad actual
          current_csv = @issue&.custom_field_value(cf_id).to_s
          current_csv = params.dig(:issue, :custom_field_values, cf_id).to_s if current_csv.blank?
          current_ids = current_csv.to_s.split(',').map(&:strip).reject(&:blank?)

          # clamping
          max_new = [MAX_FILES - current_ids.size, 0].max
          files = files.first(max_new)

          created = []
          files.each do |upload|
            next unless upload.respond_to?(:original_filename)

            fname = upload.original_filename.to_s
            ctype = (upload.content_type || '').to_s

            ext_ok  = ALLOWED_EXTS.any? { |e| fname.downcase.end_with?(e) }
            mime_ok = ALLOWED_MIMES.include?(ctype.downcase)
            unless ext_ok || mime_ok
              Rails.logger.info "[RMA-CF] CF #{cf_id}: bloqueado #{fname} (#{ctype})"
              next
            end

            att = Attachment.create!(
              file:        upload,
              author:      User.current,
              container:   (@issue if @issue&.persisted?),
              description: 'custom_field:multiple_attachments'
            )
            created << att.id
          end

          @rmacf_created_attachment_ids_by_cf[cf_id.to_s] = created
        end

        rem.each do |cf_id, ids|
          ids = Array(ids).flat_map { |x| x.to_s.split(',') }.map(&:strip).reject(&:blank?)
          @rmacf_removed_attachment_ids_by_cf[cf_id.to_s] = ids
          Rails.logger.info "[RMA-CF] CF #{cf_id}: marcados para remover #{ids.inspect}"
        end

        affected = (@rmacf_created_attachment_ids_by_cf.keys + @rmacf_removed_attachment_ids_by_cf.keys).uniq
        affected.each do |cf_id|
          current_csv = @issue&.custom_field_value(cf_id).to_s
          current_csv = params.dig(:issue, :custom_field_values, cf_id).to_s if current_csv.blank?
          current_ids = current_csv.to_s.split(',').map(&:strip).reject(&:blank?)

          current_ids += Array(@rmacf_created_attachment_ids_by_cf[cf_id]).map(&:to_s)
          current_ids -= Array(@rmacf_removed_attachment_ids_by_cf[cf_id]).map(&:to_s)

          # 🔥 HARD LIMIT: nunca permitir más de MAX_FILES al final
          if current_ids.size > MAX_FILES
            Rails.logger.info "[RMA-CF] HARD LIMIT aplicado: se recortan #{current_ids.size - MAX_FILES} IDs extras"
            current_ids = current_ids.first(MAX_FILES)
          end

          params[:issue][:custom_field_values][cf_id] = current_ids.uniq.join(',')
          
          if current_ids.size > MAX_FILES
            flash[:error] = "Solo se permiten #{MAX_FILES} archivos en este campo."
          end

          Rails.logger.info "[RMA-CF] CF #{cf_id}: CSV final -> #{params[:issue][:custom_field_values][cf_id]}"
        end
      end

      def rmacf_attach_after_save
        return unless @issue&.persisted?

        created_all = @rmacf_created_attachment_ids_by_cf.values.flatten
        removed_all = @rmacf_removed_attachment_ids_by_cf.values.flatten
        Rails.logger.info "[RMA-CF] after_save: creados=#{created_all.inspect} removidos=#{removed_all.inspect}"

        if created_all.any?
          Attachment.where(id: created_all, container_id: nil).update_all(
            container_type: 'Issue',
            container_id:   @issue.id,
            author_id:      User.current.id
          )
        end

        if removed_all.any?
          if User.current.allowed_to?(:delete_attachments, @issue.project)
            Attachment.where(id: removed_all, container_type: 'Issue', container_id: @issue.id).find_each(&:destroy)
          else
            Rails.logger.info "[RMA-CF] Sin permiso :delete_attachments; solo se quitaron del CF."
          end
        end
      end
    end
  end
end
