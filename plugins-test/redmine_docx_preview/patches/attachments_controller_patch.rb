module RedmineDocxPreview
  module AttachmentsControllerPatch
    def self.included(base)
      base.class_eval do
        before_action :convert_docx_to_pdf, only: :show

        private

        def convert_docx_to_pdf
          attachment = Attachment.find(params[:id])
          docx_path = attachment.diskfile

          Rails.logger.info "[DocxPreview] Attachment path: #{docx_path}"
          Rails.logger.info "[DocxPreview] Ejecutando como usuario: #{`whoami`.strip}"
          Rails.logger.info "[DocxPreview] Variables de entorno:\n#{`env`}"

          if File.exist?(docx_path) && File.extname(docx_path).casecmp(".docx").zero?
            Rails.logger.info "[DocxPreview] Convirtiendo .docx a PDF para attachment ##{attachment.id}"

            pdf_path = convert_to_pdf(docx_path)

            if pdf_path && File.exist?(pdf_path)
              Rails.logger.info "[DocxPreview] PDF generado en #{pdf_path}"
              Rails.logger.info "[DocxPreview] Detalles del PDF:\n#{`ls -l #{pdf_path}`}"
              Rails.logger.info "[DocxPreview] Tamaño del PDF: #{File.size(pdf_path)} bytes"

              send_file pdf_path, type: "application/pdf", disposition: "inline"
              return false # Detener acción show original
            else
              Rails.logger.error "[DocxPreview] Error: PDF no se generó para #{docx_path}"
              Rails.logger.error "[DocxPreview] Output LibreOffice:\n#{@libreoffice_output}"
              render plain: "Error al convertir archivo .docx a PDF", status: 500
              return false
            end
          end
          # Si no es docx o no existe archivo, continuar normalmente
        end

        def convert_to_pdf(docx_path)
          output_dir = "/tmp/pdfout"
          Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

          ENV['HOME'] ||= '/tmp'
          env_vars = {
            "HOME" => ENV['HOME'],
            "SAL_USE_VCLPLUGIN" => "gen" # Para que LibreOffice no dependa de GUI real
          }

          # Comando usando xvfb-run para simular entorno gráfico
          command = %Q(xvfb-run -a libreoffice --headless --nologo --nofirststartwizard --convert-to pdf "#{docx_path}" --outdir #{output_dir} 2>&1)

          # Ejecutar comando con entorno modificado
          @libreoffice_output = nil
          IO.popen(env_vars, command) do |io|
            @libreoffice_output = io.read
          end
          status = $?.exitstatus

          pdf_file = File.join(output_dir, File.basename(docx_path, File.extname(docx_path)) + ".pdf")

          if status == 0 && File.exist?(pdf_file)
            return pdf_file
          else
            Rails.logger.error "[DocxPreview] Error en conversión:\n#{@libreoffice_output}"
            return nil
          end
        end
      end
    end
  end
end
