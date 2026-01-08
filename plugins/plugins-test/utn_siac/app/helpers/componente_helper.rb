module ComponenteHelper
  def get_nombre_dimension(num)
    case num.to_i
    when 1 then "Curricular"
    when 2 then "Actividad Docente"
    when 4 then "Organizacional"
    else "-"
    end
  end
  
end
