module DpiCmiIssuePatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

     base.class_eval do
      unloadable
      before_save :normalizar_periodos, :if=> lambda{|i| i.tracker == Tracker.find_by_name("Indicador")}
      before_save :guardar_valor_historico, :if=> lambda{|i| i.tracker == Tracker.find_by_name("Indicador")}
      # Callbacks para valor valor_automatico
      before_save :actualizar_valor, :if=> lambda{|i| i.tracker == Tracker.find_by_name("Indicador") && i.valor_automatico}
      #Importante: solo actualiza valores de indicadores padre directos
      after_save :actualizar_indicador, :if => lambda{|i| i.parent && i.parent.tracker == Tracker.find_by_name("Indicador") && i.parent.valor_automatico}
      has_many :periodos, :dependent => :destroy
      has_many :historic_values, :class_name=> "HistoricValue", :dependent => :destroy
      validates :ind_min, :ind_med, :ind_max, :valor, :tipo_indicador, :alcance, :presence =>true, :if=>Proc.new{|i| i.tracker == Tracker.find_by_name("Indicador") && i.tipo_indicador!="de Resultado"}
      #validates :ind_med, :numericality => {:greater_than_or_equal_to => :ind_min, :message => "tiene que ser mayor que el minimo"}, :if=>Proc.new{|i| i.tracker == Tracker.find_by_name("Indicador") && i.tipo_indicador!="de Resultado"}
      #validates :ind_max, :numericality => {:greater_than_or_equal_to => :ind_med, :message => "tiene que ser mayor que el medio"}, :if=>Proc.new{|i| i.tracker == Tracker.find_by_name("Indicador") && i.tipo_indicador!="de Resultado"}
      # Validaciones para caso de valor automatico entre 0 y 100
      validates :ind_min, :ind_med, :ind_max, :numericality => {:greater_than_or_equal_to => 0, :message => "tiene que ser mayor o igual a 0"}, :if=>Proc.new{|i| i.valor_automatico && i.tipo_indicador!="de Resultado"}
      validates :ind_min, :ind_med, :ind_max, :numericality => {:less_than_or_equal_to => 100, :message => "tiene que ser menor o igual a 100"}, :if=>Proc.new{|i| i.valor_automatico && i.tipo_indicador!="de Resultado"}
      validate :fecha_fin_val, :if=>Proc.new{|i| i.tracker == Tracker.find_by_name("Indicador") && i.project.cmi_validar_fecha_inicio_indicadores }
      validate :fecha_inicio_val, :if=>Proc.new{|i| i.tracker == Tracker.find_by_name("Indicador") && i.project.cmi_validar_fecha_inicio_indicadores && i.tipo_indicador!="de Resultado" }
      safe_attributes :ind_min, :ind_med, :ind_max, :valor, :valor_automatico, :valor_peso, :tipo_indicador, :alcance,:periodos_attributes
      accepts_nested_attributes_for :periodos

    end
  end

  module InstanceMethods

      def actualizar_indicador
        p=self.parent
        # done ratio = weighted average ratio of leaves
        unless p.nil?
          leaves_count = p.leaves.count
          if leaves_count > 0
            # average = p.leaves.where("estimated_hours > 0").average(:estimated_hours).to_f
            # if average == 0
            #   average = 1
            # end
        #     done = p.leaves.sum("COALESCE(CASE WHEN estimated_hours > 0 THEN estimated_hours ELSE NULL END, #{average}) " +
  			# "* (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)", :joins => :status).to_f
            done = p.leaves.sum(:done_ratio)
            progress = done / leaves_count
            if p.tipo_indicador!="de Resultado"
              p.valor = progress.round
            else
              if progress==100
                  p.valor=1
              else
                  p.valor=0
              end
            end
          end
          p.save(:validate => false)
        end
      end

      def actualizar_valor
          leaves_count = self.leaves.count
          if leaves_count > 0
            # average = self.leaves.where("estimated_hours > 0").average(:estimated_hours).to_f
            # if average == 0
            #   average = 1
            # end
        #     done = self.leaves.sum("COALESCE(CASE WHEN estimated_hours > 0 THEN estimated_hours ELSE NULL END, #{average}) " +
        # "* (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)", :joins => :status).to_f
            done = self.leaves.sum(:done_ratio)
            progress = done / leaves_count
            if self.tipo_indicador!="de Resultado"
              self.valor = progress.round
            else
              if progress.round==100
                self.valor=1
              else
                self.valor=0
              end
          end
          #self.valor = progress.round
          end
      end

    def objetivos
      tracker=Tracker.find_by_name("Objetivo Especifico").try(:id)
      return self.children.where(tracker_id: tracker)
    end

    def indicadores
      tracker=Tracker.find_by_name("Indicador").try(:id)
      return self.children.where(tracker_id: tracker)
    end

    def valores_historicos
      return self.historic_values.map{|h| ["#{h.fecha}",h.valor]}.to_s
    end

    def guardar_valor_historico
      if self.valor_changed?
        historico=self.historic_values.build(:fecha=>Date.today, :valor=> self.valor)
        if !self.new_record?
          historico.save!
        end
      end
    end

    #Validar frecuencia acorde a la fecha inicio
    def fecha_inicio_val
      if self.start_date && self.due_date
        evaluacion=1+(self.due_date.month-self.start_date.month)
        case evaluacion
        when 11
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance==1
        when 10
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance==1
        when 9
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance==1
        when 8
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance==1
        when 7
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance==1
        when 6
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance==1
        when 5
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance<=2
        when 4
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance<=2
        when 3
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance<=3
        when 2
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance<=6
        when 1
          errors.add(:alcance, "es incorrecta dada la fecha de inicio y de fin.") if self.alcance!=12
        end
        #if (evaluacion==1 && self.alcance!=12) || (evaluacion>=2 && self.alcance6) || (evaluacion>=4 && self.alcance>3) || (evaluacion>=3 && self.alcance>4) || (evaluacion>=2 && self.alcance>6)
        #  errors.add(:alcance, "es incorrecta dada la fecha de inicio.")
        #end
      end
    end

    #Validar fecha fin con year = al year de fecha inicio
    def fecha_fin_val
      errors.add(:due_date, "Debe pertenecer al mismo periodo de la fecha de inicio.") if self.start_date && self.due_date && self.start_date.year!=self.due_date.year
    end

    #Parche para habilitar el renderizado de PROGRAMAS para usuarios LIDER_MEDIO que tienen objetivos asociados en dicho PROGRAMA
    # Es decir verifica si tiene peticiones hijas asociadas al usuario actual y devuelve TRUE solo en ese caso
    def renderizar_para_lider?
      result=false
      self.children.each do |child|
        result=true if User.current.is_or_belongs_to?(child.assigned_to)
      end
      return result
    end
    #
    def normalizar_periodos
      if self.tipo_indicador=="de Resultado"
        self.alcance=1
      elsif self.alcance==1
        self.periodos.delete_all
      elsif self.periodos.size == 0
        alcance_f=self.alcance.to_f
        self.alcance.times do |i|
          per=i+1
          p=self.periodos.build(:periodo=>per,:ind_min=>((self.ind_min/alcance_f)*per).round,:ind_med=>((self.ind_med/alcance_f)*per).round,
                                            :ind_max=>((self.ind_max/alcance_f)*per).round)
          p.save!
        end
      elsif self.alcance_changed? || (self.tipo_indicador_changed? && self.tipo_indicador=="Simetrico") || self.ind_min_changed? || self.ind_med_changed? || self.ind_max_changed?
        self.periodos.delete_all
        alcance_f=self.alcance.to_f
        self.alcance.times do |i|
          per=i+1
          p=self.periodos.build(:periodo=>per,:ind_min=>((self.ind_min/alcance_f)*per).round,:ind_med=>((self.ind_med/alcance_f)*per).round,
                                            :ind_max=>((self.ind_max/alcance_f)*per).round)
          p.save!
        end
      end
    end

    def issue_list(&block)
      issues=self.descendants.sort_by(&:lft)
      ancestors = []
      issues.each do |issue|
        while (ancestors.any? && !issue.is_descendant_of?(ancestors.last))
          ancestors.pop
        end
        yield issue, ancestors.size
        ancestors << issue unless issue.leaf?
      end
    end

    def estado(actual)
      if self.tracker == Tracker.find_by_name("Indicador") #INDICADOR
        if (self.start_date && self.start_date > Date.today) || (( !self.valor.nil? && !self.ind_min.nil? && !self.ind_med.nil? && !self.ind_max.nil?) && ( self.valor==0 && self.ind_min==0 && self.ind_med==0 && self.ind_max==0)) #Estado nulo si aún no empezó
          return nil
        elsif self.tipo_indicador=="de Resultado"
          if  self.valor && self.valor==1
            return 3.0
          else
            return 0.0
          end
        elsif self.valor

          if self.alcance==1 || !actual #Para alcance anual tomar solo semaforos globales
            #verificar si es ascendente o descendente
            if ((self.ind_min <= self.ind_med) && (self.ind_med<= self.ind_max))
              if  self.valor < self.ind_min
                return 0.0
              elsif self.valor >= self.ind_min && self.valor < self.ind_med
                return 1.0
              elsif self.valor >= self.ind_med && self.valor < self.ind_max
                return 2.0
              elsif self.valor >= self.ind_max
                return 3.0
              end
            else #es descendente
              if  self.valor <= self.ind_max
                return 3.0
              elsif self.valor <= self.ind_med && self.valor > self.ind_max
                return 2.0
              elsif self.valor > self.ind_med && self.valor < self.ind_min
                return 1.0
              elsif self.valor >= self.ind_min
                return 0.0
              end
            end
          else # comprar valor con semaforos para ese periodo
            semaforo=self.periodos.find_by_periodo(self.periodo_actual)
            if semaforo
              #verificar si es ascendente o descendente
              if ((self.ind_min <= self.ind_med) && (self.ind_med<= self.ind_max))
                if  self.valor < semaforo.ind_min
                  return 0.0
                elsif self.valor >= semaforo.ind_min && self.valor < semaforo.ind_med
                  return 1.0
                elsif self.valor >= semaforo.ind_med && self.valor < semaforo.ind_max
                  return 2.0
                elsif self.valor >= semaforo.ind_max
                  return 3.0
                end
              else #es descendente
                if  self.valor <= semaforo.ind_max
                  return 3.0
                elsif self.valor <= semaforo.ind_med && self.valor > semaforo.ind_max
                  return 2.0
                elsif self.valor > semaforo.ind_med && self.valor < semaforo.ind_min
                  return 1.0
                elsif self.valor >= semaforo.ind_min
                  return 0.0
                end
              end
            end
          end
        end
      else #OBJETIVO o PROGRAMA o TAREA u OTRO
        estados_subniveles=[]
        self.issue_list() do |child, level|
          if level < 1 #TRABAJAMOS SOLO SOBRE EL 1 NIVEL
            estados_subniveles << {:estado=>child.estado(actual), :peso=>child.peso}
          end
        end
        estados_subniveles.compact!
        if estados_subniveles.size == 0
          return nil
        else
          pesos=self.peso_hijas(actual)
          pesos_total= 0
          suma=0.0
          cont=0
          pesos.compact.each{|p| pesos_total+=p}
          if pesos.size > pesos.compact.size || pesos_total!=100
            #implica que hay hijas sin peso definido o el peso total no suma 100 por lo que esta mal
            estados_subniveles.each do |e|
              if !e[:estado].nil?
                suma+=e[:estado]
                cont+=1
              end
            end
            if cont > 0
              return suma/cont.to_f
            else
              return nil
            end
          else
            #implica que hay hijas con peso definido correctamente
            estados_subniveles.each do |e|
              if !e[:estado].nil? && e[:peso] >0
                suma+=e[:estado]*(e[:peso]/100.0)
                cont+=1
              end
            end
            if cont > 0
              return suma
            else
              return nil
            end
          end
        end
      end
    end

    def periodo_actual
      # calcular el periodo actual en base al alcance y la fecha actual
      mes_actual=Date.today.month
      mpp=12/self.alcance
      if mes_actual <= mpp
        periodo_actual=1
      elsif mes_actual%mpp >0
        periodo_actual=(mes_actual/mpp)+1
      else
        periodo_actual=mes_actual/mpp
      end
      return periodo_actual
    end

    def peso
      if self.valor_peso
           #tiene peso definido
        return self.valor_peso
      else
        return nil
      end
    end

    def peso_hijas(actual)
      peso_hijas=[]
      self.issue_list() do |child, level|
        if level < 1 #&& child.peso #TRABAJAMOS SOLO SOBRE EL 1 NIVEL
          peso_hijas << child.peso if child.estado(actual)
        end
      end
      return peso_hijas
    end

  end
end
