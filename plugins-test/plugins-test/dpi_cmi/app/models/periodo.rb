class Periodo < ActiveRecord::Base
  unloadable
  belongs_to :issue
  #safe_attributes :ind_min, :ind_med, :ind_max, :periodo, :issue_id
  validates :ind_min, :ind_med, :ind_max, :presence =>true
  validates :ind_med, :numericality => {:greater_than_or_equal_to => :ind_min, :message => "tiene que ser mayor que el minimo"}
  validates :ind_max, :numericality => {:greater_than_or_equal_to => :ind_med, :message => "tiene que ser mayor que el medio"}

  def periodo_evaluacion_inicio
    if self.issue.start_date
      periodos=self.issue.alcance
      ano=self.issue.start_date.year
      mpp=12/periodos
      mf=self.periodo*mpp
      mi=mf-mpp+1
      fi="01/#{mi}/#{ano}".to_date
      return fi
    else
      return nil
    end
  end

  def periodo_evaluacion_fin
    if self.issue.start_date
      periodos=self.issue.alcance
      ano=self.issue.start_date.year
      mpp=12/periodos
      mf=self.periodo*mpp
      ff="#{Time.days_in_month( mf, ano )}/#{mf}/#{ano}".to_date
      return ff
    else
      return nil
    end
  end

end
