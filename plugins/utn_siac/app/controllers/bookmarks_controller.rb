class BookmarksController < ApplicationController
  before_action :find_convocatoria
  include Siac::ControllerGuard

  before_action :deny_siac_cliente!

  def create
    @bookmark = Bookmark.new(convocatoria: @convocatoria, user_id: current_user.id)  # Guardamos el user_id aquí

    if @bookmark.save
      redirect_to convocatorias_path, notice: 'Convocatoria añadida a tus favoritos.'
    else
      redirect_to convocatorias_path, alert: 'No se pudo añadir la convocatoria a tus favoritos.'
    end
  end

  def destroy
    @bookmark = Bookmark.find_by(convocatoria: @convocatoria, user_id: current_user.id)

    if @bookmark&.destroy
      redirect_to convocatorias_path, notice: 'Convocatoria eliminada de tus favoritos.'
    else
      redirect_to convocatorias_path, alert: 'No se pudo eliminar la convocatoria de tus favoritos.'
    end
  end

  private

  def find_convocatoria
    @convocatoria = Convocatoria.find(params[:convocatoria_id])
  end
end
