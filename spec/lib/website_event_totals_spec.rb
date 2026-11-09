require 'rails_helper'

describe WebsiteEventTotals do
  let(:totals) do
    described_class.build do |b|
      b.hub        = 'Some Hub'
      b.start_date = Date.new(2025, 7, 1)
      b.end_date   = Date.new(2026, 10, 31)
    end
  end

  before do
    stub_ga_cache_passthrough
    stub_new_dimensions_date(Date.new(2026, 9, 12))
    allow(PssEvents).to receive(:build).and_return(double(total_views: 7))
    allow_any_instance_of(described_class).to receive(:builder_for) do |_totals, era|
      if era.schema == GaEventSchema::Legacy
        double(response: cached_response(%w[ga:eventCategory ga:totalEvents],
                                         [['View Item : Some Hub', '100'],
                                          ['Click Through : Some Hub', '20'],
                                          ['View Primary Source : Some Hub', '3']]))
      else
        double(response: cached_response(%w[eventName ga:totalEvents],
                                         [%w[item_view 50], %w[exhibition_item_view 4],
                                          %w[browse_item 999], ['(other)', '1']]))
      end
    end
  end

  it 'sums each event kind across both shapes, leaving browsing out' do
    expect(totals.item_events).to eq 150
    expect(totals.click_throughs).to eq 20
    expect(totals.exhibit_events).to eq 4
    expect(totals.response.rows.map(&:first)).not_to include('Browse Item', '(other)')
  end

  it 'counts source set views from page views, not either shape' do
    expect(totals.pss_events).to eq 7
    expect(totals.view_events).to eq 150 + 4 + 7
  end

  it 'keeps the GA4 counts when the source set count fails' do
    allow(PssEvents).to receive(:build).and_raise('no map')
    expect(totals.pss_events).to eq 0
    expect(totals.item_events).to eq 150
    expect(totals.error?).to be false
  end

  it 'is nil, and reports the error, when a report fails' do
    allow_any_instance_of(described_class).to receive(:builder_for).and_raise('GA4 is down')
    expect(totals.response).to be_nil
    expect(totals.error?).to be true
    expect(totals.item_events).to eq 0
  end
end
