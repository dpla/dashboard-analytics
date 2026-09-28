require 'rails_helper'

describe WebsiteOverview do
  def response(totals)
    GaPersistentCache::CachedResponse.new([], [], totals, 0)
  end

  let(:overview) do
    described_class.build do |b|
      b.hub        = 'Some Hub'
      b.start_date = Date.new(2025, 7, 1)
      b.end_date   = Date.new(2026, 10, 31)
    end
  end

  before { stub_ga_cache_passthrough }

  context 'across both shapes' do
    before do
      stub_new_dimensions_date(Date.new(2026, 9, 12))
      allow_any_instance_of(described_class).to receive(:builder_for) do |_overview, era|
        totals = era.schema == GaEventSchema::Legacy ?
          { 'ga:totalEvents' => '100', 'ga:sessions' => '40', 'ga:users' => '30' } :
          { 'ga:totalEvents' => '10', 'ga:sessions' => '4', 'ga:users' => '3' }
        double(response: response(totals))
      end
    end

    it 'sums every metric' do
      expect(overview.events).to eq 110
      expect(overview.sessions).to eq 44
      expect(overview.users).to eq 33
    end

    it 'queries each shape with its own hub filter' do
      filters = []
      allow_any_instance_of(described_class).to receive(:builder_for).and_call_original
      allow(GaResponseBuilder).to receive(:build) do |&block|
        builder = GaResponseBuilder.new
        block.call(builder)
        filters << builder.instance_variable_get(:@filters)
        double(response: response({}))
      end
      overview.response
      expect(filters).to contain_exactly(
        ['ga:eventCategory=@Some Hub', 'ga:eventCategory!@Browse'],
        [GaEventSchema::Current::COUNTED_EVENTS, 'customEvent:partner==Some Hub'])
    end
  end

  it 'is nil, and reports the error, when a report fails' do
    stub_new_dimensions_date(Date.new(2026, 11, 1))
    allow_any_instance_of(described_class).to receive(:builder_for).and_raise('GA4 is down')
    expect(overview.response).to be_nil
    expect(overview.error?).to be true
  end
end
