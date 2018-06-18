require 'rails_helper'
require 'google/apis/analytics_v3'
require 'googleauth'

describe GaResponseBuilder do

  let(:token) { "foo" }
  let(:profile_id) { "ga:123" }
  let(:start_date) { "2018-01-01" }
  let(:end_date) { "2018-01-31" }
  let(:metrics) { ["ga:totalEvents"] }
  let(:dimensions) { ["ga:eventCategory"] }
  let(:filters) { ["ga:eventCategory!@Browse"] }
  let(:sort) { ["-ga:totalEvents"] }
  let(:start_index) { 101 }
  let(:segment) { "gaid::abc" }

  # Stub Google::Apis::AnalyticsV3::AnalyticsService
  let(:analyticsService) { double }

  before do
    allow(Google::Apis::AnalyticsV3::AnalyticsService).to receive(:new)
      .and_return(analyticsService)
    allow(GaAuthorizer).to receive(:token).and_return(token)
  end

  it 'authorizes analytics service' do
    allow(analyticsService).to receive(:get_ga_data)
    expect(analyticsService).to receive(:authorization=).with(token)

    GaResponseBuilder.build { |builder| builder.profile_id="foo" }
  end

  it 'builds response with given data' do
    allow(analyticsService).to receive(:authorization=)

    expect(analyticsService).to receive(:get_ga_data).with(
      profile_id,
      start_date,
      end_date,
      metrics.join(','),
      dimensions: dimensions.join(','),
      filters: filters.join(';'),
      sort: sort,
      start_index: start_index,
      segment: segment)

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = start_date
      builder.end_date = end_date
      builder.metrics = metrics
      builder.dimensions = dimensions
      builder.filters = filters
      builder.sort = sort
      builder.start_index = start_index
      builder.segment = segment
    end
  end

  it 'retries if server error' do
    allow(analyticsService).to receive(:authorization=)
    allow(analyticsService).to receive(:get_ga_data).and_raise(Exception)
    # allow(analyticsService).to receive(:get_ga_data).and_raise(Google::Apis::ServerError)
    expect(analyticsService).to receive(:get_ga_data).exactly(3).times
    GaResponseBuilder.build { |builder| builder.profile_id="foo" }
  end
end
