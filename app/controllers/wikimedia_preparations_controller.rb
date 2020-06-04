# Handles HTTP requests for wikimedia readiness

class WikimediaPreparationsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper

  def index
    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    if params[:contributor_id]
      @contributor = Contributor.new(params[:contributor_id], params[:hub_id],
                                     @start_date, @end_date)
      initiate_contributor_wp_presenter
    else
      initiate_hub_wp_presenter
    end

    @target = params[:contributor_id] ? @contributor : @hub

    @id = params[:id]

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end

  private

  def initiate_hub_wp_presenter
    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.end_date = @end_date
    end

    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    @wp_data = wp_presenter.hub(params[:hub_id])
  end

  def initiate_contributor_wp_presenter
    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.end_date = @end_date
    end

    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    @wp_data = wp_presenter.contributor(params[:hub_id], params[:contributor_id])
  end
end
