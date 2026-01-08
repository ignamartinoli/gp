class HistoricValuesController < ApplicationController
  unloadable
  before_action :find_issue
  #before_action :find_project
  before_action :authorize

  def index
  end

  def new
    @historic_value=@issue.historic_values.new
  end

  def create
    @historic_value=@issue.historic_values.build(params[:historic_value])
    if @historic_value.save
      redirect_to issue_historic_values_path(@issue)
    else
      render "new"
    end
  end

  def edit
    @historic_value=@issue.historic_values.find(params[:id])
  end

  def update
    @historic_value=@issue.historic_values.find(params[:id])
    if @historic_value.update_attributes(params[:historic_value])
      redirect_to issue_historic_values_path(@issue)
    else
      render "edit"
    end
  end

  def destroy
    @historic_value=@issue.historic_values.find(params[:id])
    @historic_value.destroy
    redirect_to issue_historic_values_path(@issue)
  end

  private

  def find_issue
    @issue=Issue.find params[:issue_id]
    @project=@issue.project
  end

end
