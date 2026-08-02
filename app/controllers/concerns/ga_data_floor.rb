##
# Date-menu floor for GA4 pages: earliest month with data.
# GA4 starts mid-2025, years after Settings.min_date.
# Menu only: queries and clamping keep min_date, so cache keys and old
# links are unchanged.
#
module GaDataFloor
  extend ActiveSupport::Concern

  included do
    helper_method :ga4_earliest_month
  end

  # Capped at default_start_date: the menu must offer it.
  def picker_min_date
    @picker_min_date ||= [earliest_data_month || min_date, default_start_date].min
  end

  ##
  # First month with GA4 activity; site-wide when no hub or contributor.
  # nil when unknown: no data, or the query failed.
  #
  def ga4_earliest_month
    return @ga4_earliest_month if defined?(@ga4_earliest_month)

    @ga4_earliest_month = WebsiteActivityMonths.build do |b|
      b.hub         = ga4_floor_hub
      b.contributor = ga4_floor_contributor
      b.start_date  = min_date
      # Not max_date: always S3-storable, so the first days of a month
      # hit last month's stored entry, not live GA4.
      b.end_date    = GaPersistentCache.settled_boundary - 1
    end.earliest_month
  end

  private

  # Override where a page also shows non-GA4 data (see HubsController).
  def earliest_data_month
    ga4_earliest_month
  end

  def ga4_floor_hub
    params[:hub_id]
  end

  def ga4_floor_contributor
    params[:contributor_id]
  end
end
