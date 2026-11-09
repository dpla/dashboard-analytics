require 'rails_helper'

describe WebsiteEventsByContributor do
  let(:long_name) { 'University of Somewhere, School of Something Very Long' }
  let(:events) do
    described_class.build do |b|
      b.hub        = 'Some Hub'
      b.start_date = Date.new(2026, 9, 1)
      b.end_date   = Date.new(2026, 9, 30)
    end
  end

  before do
    stub_ga_cache_passthrough
    stub_new_dimensions_date(Date.new(2026, 9, 12))
    allow_any_instance_of(described_class).to receive(:builder_for) do |_events, era|
      if era.schema == GaEventSchema::Legacy
        double(response: cached_response(%w[ga:eventCategory ga:eventAction ga:totalEvents],
                                  [['View Item : Some Hub', long_name[0, 40], '10'],
                                   ['Click Through : Some Hub', 'Library B', '2']]))
      else
        double(response: cached_response(%w[eventName customEvent:contributor ga:totalEvents],
                                  [['item_view', long_name, '5'],
                                   ['click_through', long_name, '1'],
                                   ['browse_item', 'Library B', '50']]))
      end
    end
  end

  it 'sums views and click throughs per contributor across both shapes' do
    expect(events.parse_data).to eq(
      long_name[0, 40] => { 'Views' => 15, 'Click Throughs' => 1 },
      'Library B'      => { 'Views' => 0, 'Click Throughs' => 2 })
  end
end
