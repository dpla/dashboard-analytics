require 'rails_helper'

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
    allow(analyticsService).to receive(:authorization=)
    allow(analyticsService).to receive(:get_ga_data)
    allow(GaAuthorizer).to receive(:token).and_return(token)
  end

  it 'authorizes analytics service on build' do
    expect(analyticsService).to receive(:authorization=).with(token)
    GaResponseBuilder.build { |builder| builder.profile_id = profile_id }
  end

  it 'builds response with given data' do
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
    end.response
  end

  it 'retries twice if server error' do
    allow(analyticsService).to receive(:get_ga_data)
      .and_raise(Google::Apis::ServerError, "oops")
    expect(analyticsService).to receive(:get_ga_data).exactly(3).times
    GaResponseBuilder.build { |builder| builder.profile_id = profile_id }
      .response
  end

  it 'retries once if authorization error' do
    allow(analyticsService).to receive(:get_ga_data)
      .and_raise(Google::Apis::AuthorizationError, "oops")
    expect(analyticsService).to receive(:get_ga_data).exactly(2).times
    GaResponseBuilder.build { |builder| builder.profile_id = profile_id }
      .response
  end

  it 'reauthorizes if authorization error' do
    allow(analyticsService).to receive(:get_ga_data)
      .and_raise(Google::Apis::AuthorizationError, "oops")
    expect(analyticsService).to receive(:authorization=).exactly(2).times
    GaResponseBuilder.build { |builder| builder.profile_id = profile_id }
      .response
  end

  it 'handles multi-page response' do
    builder = GaResponseBuilder.build { |builder| builder.profile_id = profile_id }

    page_1 = double
    allow(page_1).to receive(:next_link)
      .and_return "https://googleapis.com?start-index=1001"

    page_2 = double
    allow(page_2).to receive(:next_link).and_return(nil)

    allow(builder).to receive(:response).and_return(page_1, page_2)
    
    response = builder.multi_page_response
    expect(response).to eq [page_1, page_2]
  end
end
