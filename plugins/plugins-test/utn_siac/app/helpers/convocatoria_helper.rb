module ConvocatoriaHelper
  def get_nombre_titulacion(num)
    case num.to_i
    when 1 then "Licenciaturas"
    when 2 then "Ingenierías"
    when 3 then "Terciarios"
    when 4 then "Tecnicaturas"
    when 5 then "Maestrías"
    when 6 then "Doctorados"
    else "-"
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
