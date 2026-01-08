class HistoricValue < ActiveRecord::Base
  unloadable
  belongs_to :issue
  #safe_attributes :ind_min, :ind_med, :ind_max, :periodo, :issue_id
end
