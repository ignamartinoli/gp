class DimensionController < ApplicationController
  include Siac::ControllerGuard

  before_action :deny_siac_cliente!

  def index
    @componentes = Componente.page(params[:page])
      .per(10)
      .order(dimension_id: :desc)
  end  

  def new
    @componente = Componente.new
  end

  def create
    @dimension = Dimension.new(dimension_params)

    if @dimension.save
      flash[:notice] = "Dimensión creada con éxito."
      redirect_to dimensiones_path
    else
      flash[:alert] = "Hubo un error al crear la dimensión."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @dimension = Dimension.find(params[:id])
  end

  def update
    @dimension = Dimension.find(params[:id])

    if @dimension.update(dimension_params)
      flash[:notice] = "Dimensión actualizada correctamente."
      redirect_to dimensiones_path
    else
      flash[:alert] = "No se pudo actualizar la dimensión."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dimension = Dimension.find(params[:id])
    @dimension.destroy
    flash[:notice] = "Dimensión eliminada."
    redirect_to dimensiones_path
  end

  private

  def dimension_params
    params.require(:dimension).permit(:nombre, :descripcion)
  end
end
