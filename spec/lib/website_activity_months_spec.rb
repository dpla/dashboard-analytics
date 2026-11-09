require 'rails_helper'

describe WebsiteActivityMonths do
  let(:activity) do
    described_class.build do |b|
      b.hub        = 'Some Hub'
      b.start_date = Date.new(2018, 1, 1)
      b.end_date   = Date.new(2026, 6, 30)
    end
  end

  describe '#earliest_month' do
    it 'returns the first day of the first month with activity' do
      allow(activity).to receive(:response)
        .and_return(double(rows: [%w[202505 12], %w[202506 40]]))
      expect(activity.earliest_month).to eq Date.new(2025, 5, 1)
    end

    it 'is nil when the target has no activity' do
      allow(activity).to receive(:response).and_return(double(rows: []))
      expect(activity.earliest_month).to be_nil
    end

    it 'is nil when the query failed' do
      allow(activity).to receive(:response).and_return(nil)
      expect(activity.earliest_month).to be_nil
    end

    it 'skips rows that are not year-months' do
      allow(activity).to receive(:response)
        .and_return(double(rows: [['(other)', '5'], %w[202507 8]]))
      expect(activity.earliest_month).to eq Date.new(2025, 7, 1)
    end
  end

  describe '#response' do
    before do
      stub_ga_cache_passthrough
      stub_new_dimensions_date(Date.new(2026, 5, 12))
      allow_any_instance_of(described_class).to receive(:builder_for) do |_activity, era|
        rows = era.schema == GaEventSchema::Legacy ?
          [%w[202504 3], %w[202505 4]] : [%w[202505 6], %w[202506 1]]
        double(response: cached_response(%w[yearMonth ga:totalEvents], rows))
      end
    end

    it 'joins both shapes by month, earliest first' do
      expect(activity.response.rows).to eq [%w[202504 3], %w[202505 10], %w[202506 1]]
      expect(activity.earliest_month).to eq Date.new(2025, 4, 1)
    end
  end
end
