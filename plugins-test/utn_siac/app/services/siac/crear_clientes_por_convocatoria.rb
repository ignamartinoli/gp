module Siac
  class CrearClientesPorConvocatoria
    def initialize(convocatoria)
      @convocatoria = convocatoria
    end

    def call
      regionales.each do |regional|
        cliente = find_or_create_cliente_padre(regional)

        SiacConvocatoriaCliente.find_or_create_by!(
          convocatoria: @convocatoria,
          siac_cliente: cliente
        )
      end
    end

    private

    def regionales
      @convocatoria
        .sedes
        .includes(:regional)
        .map(&:regional)
        .compact
        .uniq
    end

    def find_or_create_cliente_padre(regional)
      cliente = SiacCliente.find_by(
        regional_id: regional.id,
        parent_id: nil
      )
      return cliente if cliente

      cf_fr = UserCustomField.find(53)
      cf_rol = UserCustomField.find(52)

      facultad_valida = facultad_regional_valida(regional, cf_fr)

      unless facultad_valida
        raise "No se pudo mapear la Facultad Regional: #{regional.nombre}"
      end

      login = login_para(regional)
      mail  = mail_para(regional)

      user = User.find_by(login: login)

      password = password_para(regional)

      user = User.create!(
        login: login,
        firstname: 'SIAC',
        lastname: apellido_para(regional),
        mail: mail,
        status: User::STATUS_ACTIVE,
        language: 'es',
        password: password,
        password_confirmation: password,
        must_change_passwd: false, # 👈 para poder probar sin fricción
        custom_field_values: {
          cf_rol.id => 'Planeamiento',
          cf_fr.id  => facultad_valida
        }
      )


      SiacCliente.create!(
        user: user,
        regional: regional,
        parent_id: nil
      )
    end


   def login_para(regional)
      "siac_fr_#{regional.id}"
    end

    def mail_para(regional)
      "siac_fr_#{regional.id}@siac.com"
    end

    def apellido_para(regional)
      regional.nombre.sub(/^Facultad Regional\s+/i, '').strip
    end

    def normalizar_regional(nombre)
      nombre
        .downcase
        .tr(
          'áéíóúüñ',
          'aeiouun'
        )
        .gsub(/\b(del|de|la|las|los)\b/, '')
        .gsub(/\s+/, ' ')
        .strip
    end

    def facultad_regional_valida(regional, cf_fr)
      normalizada = normalizar_regional(regional.nombre)

      cf_fr.possible_values.find do |valor|
        normalizar_regional(valor) == normalizada
      end
    end

    def password_para(regional)
      "FR#{regional.id}_SIAC"
    end


  end
end
