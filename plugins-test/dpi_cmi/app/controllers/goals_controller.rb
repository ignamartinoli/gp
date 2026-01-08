# encoding: UTF-8
class GoalsController < ApplicationController
  unloadable

  before_action :find_project
  before_action :authorize, only: [:index]


  def update_settings
    @project.safe_attributes = params[:project]
    if @project.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to settings_project_path(@project, :tab => 'CMI')
        }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html {
          settings
          render :action => 'settings', :tab => 'CMI'
        }
        format.api  { render_validation_errors(@project) }
      end
    end
  end

  def reporte_cmi
    if params[:opciones]
      #@show_indicators = params[:opciones].include?('indicators')
      @show_sublevel = params[:opciones].include?('sublevels')
      @show_allsublevels= params[:opciones].include?('allsublevels')
      @show_peso= params[:opciones].include?('peso')
      @show_calculo_actual= params[:opciones].include?('calculo_actual')
      session[:cmi_opciones]=[@show_sublevel, @show_allsublevels, @show_peso, @show_calculo_actual ]
    elsif session[:cmi_opciones] && !session[:cmi_opciones].empty?
      #@show_indicators = session[:cmi_opciones][0]
      @show_allsublevels= session[:cmi_opciones][0]
      @show_sublevel = session[:cmi_opciones][1]
      @show_peso = session[:cmi_opciones][2]
      @show_calculo_actual = session[:cmi_opciones][3]
    else
      #@show_indicators = true
      @show_allsublevels= true
      @show_sublevel = true
      @show_peso = false
      @show_calculo_actual = false
    end
    #@opciones=[@show_indicators, @show_sublevel, @show_allsublevels, @show_peso ]
    @cmi_versions=@project.versions.order("id desc").to_a
    @cmi_versions.delete_if{|v| !@project.cmi_versions.include?(v.id.to_s) }
    @planned_version = params[:version] || @cmi_versions.first.try(:id)
    tracker = Tracker.where(name: "Objetivo").first
    if @project.perspectiva_cf.nil?
      perspectiva_cf = tracker.custom_fields.where(name: "Perspectiva").first.id
    else
      perspectiva_cf = @project.perspectiva_cf
    end
    if @project.cmi_show_subprojects_tasks
      projects_ok=@project.children.map(&:id)<<@project.id
    else
      projects_ok=[@project.id]
    end
    #Perspectivas a usar => @VALUES
    @values = tracker.custom_fields.where(id: perspectiva_cf).first.try(:possible_values)

    #PARCHE PARA LIDER MEDIO
    if User.current.roles_for_project(@project).include?(Role.find_by_name("PEI_Lider"))
      # Por cada perspectiva busco las peticiones que la tienen seteada (y claro incluyen ese campo personalizado)
      # Obtenemos un array de longitud igual a la cantidad de perspectivas
      # Cada elemento del array es un array de peticiones vinculadas a esa perspectiva
        @programas  = @values.map do |v|
          CustomValue.where(value: v, customized_type: "Issue", custom_field_id: perspectiva_cf).map do |cv|
            if @planned_version
              cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.fixed_version_id == @planned_version.to_i && (cv.customized.visible? || cv.customized.visible?))
            else
              cv.customized if (projects_ok.include?(cv.customized.project.id) && (cv.customized.visible? || cv.customized.renderizar_para_lider?))
            end
          end.compact
        end

    else

      # Por cada perspectiva busco las peticiones que la tienen seteada (y claro incluyen ese campo personalizado)
      # Obtenemos un array de longitud igual a la cantidad de perspectivas
      # Cada elemento del array es un array de peticiones vinculadas a esa perspectiva
        @programas  = @values.map do |v|
          CustomValue.where(value: v, customized_type: "Issue", custom_field_id: perspectiva_cf).map do |cv|
            if @planned_version
              cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.fixed_version_id == @planned_version.to_i && cv.customized.visible?)
            else
              cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.visible?)
            end
          end.compact
        end

    end
    render "goals/reporte_cmi"
  end

  def reporte_indicador
    if session[:cmi_opciones] && !session[:cmi_opciones].empty?
      #@show_indicators = session[:cmi_opciones][0]
      @show_allsublevels= session[:cmi_opciones][0]
      @show_sublevel = session[:cmi_opciones][1]
      @show_peso = session[:cmi_opciones][2]
      @show_calculo_actual = session[:cmi_opciones][3]
    else
      #@show_indicators = true
      @show_allsublevels= true
      @show_sublevel = true
      @show_peso = false
      @show_calculo_actual = false
    end
    if @project.perspectiva_cf.nil?
      @perspectiva_cf = tracker.custom_fields.where(name: "Perspectiva").first.id
    else
      @perspectiva_cf = @project.perspectiva_cf
    end
    @goal=Issue.find_by_id(params[:id_ind])
    if @project.cmi_show_subprojects_tasks
      projects_ok=@project.children.map(&:id)<<@project.id
    else
      projects_ok=[@project.id]
    end

    @programa=@goal.parent.parent
    @valor_perspectiva=@programa.custom_value_for(@perspectiva_cf)
    @lista=CustomValue.where(value: @valor_perspectiva, customized_type: "Issue", custom_field_id: @perspectiva_cf).map do |cv|
        cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.visible?)
    end.compact
    render "goals/reporte_indicador"
  end

  def index
    if params[:opciones]
      #@show_indicators = params[:opciones].include?('indicators')
      @show_sublevel = params[:opciones].include?('sublevels')
      @show_allsublevels= params[:opciones].include?('allsublevels')
      @show_peso= params[:opciones].include?('peso')
      @show_calculo_actual= params[:opciones].include?('calculo_actual')
      session[:cmi_opciones]=[@show_sublevel, @show_allsublevels, @show_peso, @show_calculo_actual ]
    elsif session[:cmi_opciones] && !session[:cmi_opciones].empty?
      #@show_indicators = session[:cmi_opciones][0]
      @show_allsublevels= session[:cmi_opciones][0]
      @show_sublevel = session[:cmi_opciones][1]
      @show_peso = session[:cmi_opciones][2]
      @show_calculo_actual = session[:cmi_opciones][3]
    else
      #@show_indicators = true
      @show_allsublevels= true
      @show_sublevel = true
      @show_peso = false
      @show_calculo_actual = false
    end
    #@opciones=[@show_indicators, @show_sublevel, @show_allsublevels, @show_peso ]
    @cmi_versions=@project.versions.order("id desc").to_a
    @cmi_versions.delete_if{|v| !@project.cmi_versions.include?(v.id.to_s) }
    @planned_version = params[:version] || @cmi_versions.first.try(:id)
    tracker = Tracker.where(name: "Objetivo").first
    if @project.perspectiva_cf.nil?
      perspectiva_cf = tracker.custom_fields.where(name: "Perspectiva").first.id
    else
      perspectiva_cf = @project.perspectiva_cf
    end
    if @project.cmi_show_subprojects_tasks
      projects_ok=@project.children.map(&:id)<<@project.id
    else
      projects_ok=[@project.id]
    end
    #Perspectivas a usar => @VALUES
    @values = tracker.custom_fields.where(id: perspectiva_cf).first.try(:possible_values)

    #PARCHE PARA LIDER MEDIO
    if User.current.roles_for_project(@project).include?(Role.find_by_name("PEI_Lider"))
      # Por cada perspectiva busco las peticiones que la tienen seteada (y claro incluyen ese campo personalizado)
      # Obtenemos un array de longitud igual a la cantidad de perspectivas
      # Cada elemento del array es un array de peticiones vinculadas a esa perspectiva
        @goals  = @values.map do |v|
          CustomValue.where(value: v, customized_type: "Issue", custom_field_id: perspectiva_cf).map do |cv|
            if @planned_version
              cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.fixed_version_id == @planned_version.to_i && (cv.customized.visible? || cv.customized.visible?))
            else
              cv.customized if (projects_ok.include?(cv.customized.project.id) && (cv.customized.visible? || cv.customized.renderizar_para_lider?))
            end
          end.compact
        end

    else

      # Por cada perspectiva busco las peticiones que la tienen seteada (y claro incluyen ese campo personalizado)
      # Obtenemos un array de longitud igual a la cantidad de perspectivas
      # Cada elemento del array es un array de peticiones vinculadas a esa perspectiva
        @goals  = @values.map do |v|
          CustomValue.where(value: v, customized_type: "Issue", custom_field_id: perspectiva_cf).map do |cv|
            if @planned_version
              cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.fixed_version_id == @planned_version.to_i && cv.customized.visible?)
            else
              cv.customized if (projects_ok.include?(cv.customized.project.id) && cv.customized.visible?)
            end
          end.compact
        end

    end
    @goals_padres=[]
    @goals.each{|goal_list| @goals_padres+=goal_list}
    respond_to do |format|
      format.html { render :action => "index"}
      format.png  {
        imagen=render_to_string(:action => "index", :encoding => 'UTF-8')
        @kit = IMGKit.new(imagen, :quality => 50, :encoding => 'utf8', :height=>0)
        @kit.stylesheets << "#{Rails.root.to_s}/plugins/dpi_cmi/assets/stylesheets/goals.css"
        send_data(@kit.to_png, :type => "image/png", :disposition => 'inline', :filename => "cmi.png")
      }
    end
  end
end
