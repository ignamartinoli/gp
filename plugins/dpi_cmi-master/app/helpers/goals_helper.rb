module GoalsHelper
  def goal_link(goal)
    return "<span class='goal #{indicator_class(goal)}'>#{goal.tracker.name.upcase}:</span> #{goal.subject}".html_safe
  end

  def indicator_class(resource)
    if resource.estado(@show_calculo_actual)
      if resource.tracker == Tracker.find_by_name("Indicador")
        if resource.estado(@show_calculo_actual) == 3.0
          "green"
        elsif resource.estado(@show_calculo_actual) == 2.0
          "yellow"
        elsif resource.estado(@show_calculo_actual) == 1.0
          "orange"
        else
          "red"
        end
      else #Colorear OBJETIVOS o PROGRAMAS - Acorde al nivel
        #TODO: Incorporar valores en setings para personalizar el coloreo
        if resource.estado(@show_calculo_actual) >= 2.75
          "green"
        elsif resource.estado(@show_calculo_actual) >= 2.0
          "yellow"
        elsif resource.estado(@show_calculo_actual) >= 1.0
          "orange"
        else
          "red"
        end
      end
    end
  end

  def calculate_ratio(collection)
    "#{collection.map(&:done_ratio).inject(:+) / collection.count}%" if collection.present?
  end

  def link_text(indicator)
    indicator.present? ? I18n.t('cmi.hideactualdate') : I18n.t('cmi.showactualdate')
  end

  def link_text_subleves(indicator)
    indicator.present? ? I18n.t('cmi.hidesublevels') : I18n.t('cmi.showsublevels')
  end
  def link_text_allsubleves(indicator)
    indicator.present? ? I18n.t('cmi.onlyonesublevel') : I18n.t('cmi.allsublevels')
  end

  def issue_list(issues, &block)
    ancestors = []
    issues.each do |issue|
      while (ancestors.any? && !issue.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield issue, ancestors.size
      ancestors << issue unless issue.leaf?
    end
  end

  def render_descendants_tree(issue, lista_padres)
    s = '<table class="list issues" id="subniveles">'
    issue_list(issue.descendants.order("issues.subject desc")) do |child, level|
      if child.visible?
        css = "fila issue "
        css << "idnt idnt-#{level} " if level > 0
        if @show_allsublevels && @project.cmi_show_trackers.include?(child.tracker_id.to_s) && !lista_padres.include?(child)
          css << (indicator_class(child) || " ") #if (child.descendants.select{ |g| g.tracker.name == "Indicador" }.first )
          contenido=""
          contenido<<content_tag('td',link_to_issue(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject')
          if @show_peso
            if !child.peso.nil?
              contenido<<content_tag('td',"#{child.peso}%")
            else
              contenido<<content_tag('td',"N/D")
            end
          end
          s << content_tag('tr',contenido.html_safe, :class => css)
        elsif level < 1 && @project.cmi_show_trackers.include?(child.tracker_id.to_s) && !lista_padres.include?(child)#AQUI AJUSTAR EL NIVEL A MOSTRAR
          css << (indicator_class(child) || " ") #if (child.descendants.select{ |g| g.tracker.name == "Indicador" }.first )
          contenido=""
          contenido<<content_tag('td',link_to_issue(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject')
          if @show_peso
            if !child.peso.nil?
              contenido<<content_tag('td',"#{child.peso}%")
            else
              contenido<<content_tag('td',"N/D")
            end
          end
          s << content_tag('tr',contenido.html_safe, :class => css)
        end
      end
    end
    s << '</table>'
    s.html_safe
  end

  def render_descendants_tree_png(issue)
    s = ''
    issue_list(issue.descendants.order("issues.subject desc").visible) do |child, level|
      if child.visible?
        css = "issue "
        css << "idnt idnt-#{level} " if level > 0
        if @show_allsublevels && @project.cmi_show_trackers.include?(child.tracker_id.to_s)
          css << (indicator_class(child) || " ") #if (child.descendants.select{ |g| g.tracker.name == "Indicador" }.first )
          contenido=""
          contenido<<content_tag('td',link_to_issue_png(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject')
          if @show_peso
            if !child.peso.nil?
              contenido<<content_tag('td',"#{child.peso}%")
            else
              contenido<<content_tag('td',"N/D")
            end
          end
          s << content_tag('tr',contenido.html_safe, :class => css)
        elsif level < 1 && @project.cmi_show_trackers.include?(child.tracker_id.to_s) #AQUI AJUSTAR EL NIVEL A MOSTRAR
          css << (indicator_class(child) || " ") #if (child.descendants.select{ |g| g.tracker.name == "Indicador" }.first )
          contenido=""
          contenido<<content_tag('td',link_to_issue_png(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject')
          if @show_peso
            if !child.peso.nil?
              contenido<<content_tag('td',"#{child.peso}%")
            else
              contenido<<content_tag('td',"N/D")
            end
          end
          s << content_tag('tr',contenido.html_safe, :class => css)
        end
      end
    end
    s << ''
    s.html_safe
  end

  def render_descendants_tree_doc(issue)
    s = '<table class="list issues" id="subniveles">'
    issue_list(issue.descendants.order("issues.subject desc").visible) do |child, level|
      if child.visible?
        css = "fila issue "
        css << "idnt idnt-#{level} " if level > 0
        if @show_allsublevels && @project.cmi_show_trackers.include?(child.tracker_id.to_s)
          css << (indicator_class(child) || " ") #if (child.descendants.select{ |g| g.tracker.name == "Indicador" }.first )
          contenido=""
          contenido<<content_tag('td',link_to_issue_doc(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject')
          if @show_peso
            if !child.peso.nil?
              contenido<<content_tag('td',"#{child.peso}%")
            else
              contenido<<content_tag('td',"N/D")
            end
          end
          s << content_tag('tr',contenido.html_safe, :class => css)
        elsif level < 1 && @project.cmi_show_trackers.include?(child.tracker_id.to_s) #AQUI AJUSTAR EL NIVEL A MOSTRAR
          css << (indicator_class(child) || " ") #if (child.descendants.select{ |g| g.tracker.name == "Indicador" }.first )
          contenido=""
          contenido<<content_tag('td',link_to_issue_doc(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject')
          if @show_peso
            if !child.peso.nil?
              contenido<<content_tag('td',"#{child.peso}%")
            else
              contenido<<content_tag('td',"N/D")
            end
          end
          s << content_tag('tr',contenido.html_safe, :class => css)
        end
      end
    end
    s << '</table>'
    s.html_safe
  end

  def link_to_issue_doc(issue, options={})
    title = nil
    subject = nil
    level_indent="&nbsp;"*issue.level
    text = "#"+issue.id.to_s+" "+issue.tracker.name
    title = issue.tracker.name#+": "+issue.subject.truncate(60)
    subject = issue.subject
    s = level_indent+text+": "+subject
    s.html_safe
  end

  def link_to_issue_png(issue, options={})
    title = nil
    subject = nil
    level_indent="&nbsp;"*issue.level
    text = abreviate_tracker(issue.tracker.name)
    title = issue.tracker.name#+": "+issue.subject.truncate(60)
    subject = issue.subject
    s = level_indent+text+": "+subject
    s.html_safe
  end

  def link_to_issue(issue, options={})
    title = nil
    subject = nil
    text = abreviate_tracker(issue.tracker.name)
    if issue.tracker==Tracker.find_by_name("Indicador")
      if issue.tipo_indicador=="de Resultado" && issue.valor == 1
        title = "Indicador de resultado alcanzado"
      elsif issue.tipo_indicador=="de Resultado"
        title = "Indicador de resultado no alcanzado"
      elsif issue.valor==0 && issue.ind_min==0 && issue.ind_med==0 && issue.ind_max==0
        title= "Indicador no seteado (todos los valores estan en cero)."
      elsif issue.alcance>1 && @show_calculo_actual
        #Si es indicador asimetrico y estamos mostrando calculo actual
        semaforo=issue.periodos.find_by_periodo(issue.periodo_actual)
        title = "Valor Actual = #{number_with_delimiter(issue.valor, :delimiter => '.')} (Min=#{number_with_delimiter(semaforo.ind_min, :delimiter => '.')}/Med=#{number_with_delimiter(semaforo.ind_med, :delimiter => '.')}/Max=#{number_with_delimiter(semaforo.ind_max, :delimiter => '.')})"
      else
        title = "Valor Actual = #{number_with_delimiter(issue.valor, :delimiter => '.')} (Min=#{number_with_delimiter(issue.ind_min, :delimiter => '.')}/Med=#{number_with_delimiter(issue.ind_med, :delimiter => '.')}/Max=#{number_with_delimiter(issue.ind_max, :delimiter => '.')})"
      end
    else
      title = issue.tracker.name#+": "+issue.subject.truncate(60)
    end
    subject = issue.subject
    s = link_to(text+": "+subject, issue_path(issue, :only_path => true), target: "_blank",
                :class => issue.css_classes, :title => title)
    s
  end

  def abreviate_tracker(tracker_name)
    return_string=""
    tracker_name.split.each{|word| return_string<<word.capitalize[0]}
    return return_string
  end
end
