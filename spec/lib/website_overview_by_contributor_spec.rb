require 'rails_helper'

describe WebsiteOverviewByContributor do
  let(:long_name) { 'University of Somewhere, School of Something Very Long' }
  let(:overview) do
    described_class.build do |b|
      b.hub        = 'Some Hub'
      b.start_date = Date.new(2026, 9, 1)
      b.end_date   = Date.new(2026, 9, 30)
    end
  end

  before do
    stub_ga_cache_passthrough
    stub_new_dimensions_date(Date.new(2026, 9, 12))
    allow_any_instance_of(described_class).to receive(:builder_for) do |_overview, era|
      if era.schema == GaEventSchema::Legacy
        double(response: cached_response(%w[ga:eventAction ga:sessions ga:users],
                                  [[long_name[0, 40], '10', '8'], ['Library B', '2', '2']]))
      else
        double(response: cached_response(%w[customEvent:contributor ga:sessions ga:users],
                                  [[long_name, '5', '4']]))
      end
    end
  end

  it 'sums sessions and users per contributor across both shapes' do
    expect(overview.parse_data).to eq(
      long_name[0, 40] => { 'Sessions' => 15, 'Users' => 12 },
      'Library B'      => { 'Sessions' => 2, 'Users' => 2 })
  end
end
