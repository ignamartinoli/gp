module ConvocatoriaHelper
  def get_nombre_titulacion(num)
    case num.to_i
    when 3
      "Carrera de Grado"
    when 11
      "Ciclo de Licenciatura"
    when 12
      "Técnico Superior"
    when 5
      "Maestría"
    when 6
      "Doctorado"
    else
      "-"
    end
  end


  def get_nombre_dimension(num)
    case num.to_i
    when 1 then "Curricular"
    when 2 then "Actividad Docente"
    when 4 then "Organizacional"
    else "-"
    end
  end
  
end
