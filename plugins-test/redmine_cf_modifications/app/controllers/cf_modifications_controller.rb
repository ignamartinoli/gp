# plugins/redmine_cf_modifications/app/controllers/cf_modifications_controller.rb
class CfModificationsController < ApplicationController
  before_action :find_custom_field
  before_action :require_admin

  def convert_field
    if @custom_field.field_format == 'attachment'
      # ⚠️ Usa update_columns para saltear validaciones de formato
      @custom_field.update_columns(field_format: 'multiple_attachment')
      flash[:notice] = 'El campo fue convertido correctamente a Multiple Attachments.'
    else
      flash[:error] = 'Este campo no es de tipo Attachment.'
    end
    redirect_to edit_custom_field_path(@custom_field)
  end

  private

  def find_custom_field
    @custom_field = CustomField.find(params[:id])
  end
end
