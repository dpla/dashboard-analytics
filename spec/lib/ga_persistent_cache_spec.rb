require 'rails_helper'

describe GaPersistentCache do
  before { allow(Date).to receive(:current).and_return(Date.new(2026, 7, 15)) }

  describe '.cacheable?' do
    it 'is true for a range ending in a completed month' do
      expect(described_class.cacheable?(Date.new(2026, 6, 30))).to be true
    end

    it 'is false for a range ending in the current month' do
      expect(described_class.cacheable?(Date.new(2026, 7, 10))).to be false
    end

    it 'is false without an end date' do
      expect(described_class.cacheable?(nil)).to be false
    end

    context 'during the settling window at the start of a month' do
      before { allow(Date).to receive(:current).and_return(Date.new(2026, 7, 2)) }

      it 'is false for the just-completed month' do
        expect(described_class.cacheable?(Date.new(2026, 6, 30))).to be false
      end

      it 'is true for earlier months' do
        expect(described_class.cacheable?(Date.new(2026, 5, 31))).to be true
      end
    end

    # Absolute dates on purpose: raising SETTLING_DAYS past 4 silently
    # no-ops the day-5 cron, and these must fail then.
    it 'is false for the just-completed month on day 4' do
      allow(Date).to receive(:current).and_return(Date.new(2026, 7, 4))
      expect(described_class.cacheable?(Date.new(2026, 6, 30))).to be false
    end

    it 'is true for the just-completed month on day 5, when the warm job runs' do
      allow(Date).to receive(:current).and_return(Date.new(2026, 7, 5))
      expect(described_class.cacheable?(Date.new(2026, 6, 30))).to be true
    end
  end

  describe '.fetch' do
    let(:key) { 'ga:website_events:Some Hub::Click Through:2026-01-01:2026-06-30:page1' }
    let(:end_date) { Date.new(2026, 6, 30) }
    let(:rows) { [%w[abc123 42]] }
    let(:response) do
      double(
        column_headers: [GaResponseBuilder::Ga4Response::ColumnHeader.new('ga:eventLabel')],
        rows: rows,
        totals_for_all_results: { 'ga:totalEvents' => '42' },
        total_results: 1
      )
    end

    before do
      allow(SThreeResponseBuilder).to receive(:response)
        .and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'no such key'))
    end

    it 'passes straight through to the block when the range is not permanently cacheable' do
      expect(SThreeResponseBuilder).not_to receive(:response)
      expect(described_class.fetch(key, Date.new(2026, 7, 10)) { :live }).to eq :live
    end

    it 'stores the block result on a miss and returns the stored form' do
      written = nil
      expect(SThreeResponseBuilder).to receive(:put) do |s3_key, body|
        expect(s3_key).to start_with described_class::PREFIX
        written = body
      end

      result = described_class.fetch(key, end_date) { response }
      expect(result.rows).to eq rows
      expect(JSON.parse(written)['rows']).to eq rows
    end

    it 'returns the stored response without running the block on a hit' do
      body = JSON.generate(
        'columns' => ['ga:eventLabel'], 'rows' => rows,
        'totals' => { 'ga:totalEvents' => '42' }, 'total_results' => 1
      )
      allow(SThreeResponseBuilder).to receive(:response)
        .and_return(double(body: StringIO.new(body)))

      cached = described_class.fetch(key, end_date) { raise 'block should not run' }
      expect(cached.rows).to eq rows
      expect(cached.column_headers.map(&:name)).to eq ['ga:eventLabel']
      expect(cached.total_results).to eq 1
      expect(cached.totals_for_all_results).to eq('ga:totalEvents' => '42')
    end

    it 'round-trips a multi-page response as an array' do
      written = nil
      allow(SThreeResponseBuilder).to receive(:put) { |_k, body| written = body }

      result = described_class.fetch(key, end_date) { [response, response] }

      expect(JSON.parse(written).length).to eq 2
      expect(result.length).to eq 2
      expect(result.first.rows).to eq rows
    end

    it 'falls through to the block when the read fails' do
      allow(SThreeResponseBuilder).to receive(:response)
        .and_raise(Aws::S3::Errors::ServiceError.new(nil, 'boom'))
      allow(SThreeResponseBuilder).to receive(:put)
      expect(described_class.fetch(key, end_date) { response }.rows).to eq rows
    end

    it 'still returns the live response when the write fails' do
      allow(SThreeResponseBuilder).to receive(:put)
        .and_raise(Aws::S3::Errors::ServiceError.new(nil, 'boom'))
      expect(described_class.fetch(key, end_date) { response }).to eq response
    end

    it 'does not store nil block results' do
      expect(SThreeResponseBuilder).not_to receive(:put)
      expect(described_class.fetch(key, end_date) { nil }).to be_nil
    end

    # An empty export must store and read back as a hit, not read as a miss
    # that re-runs the GA4 export on every request.
    it 'round-trips an empty multi-page response' do
      written = nil
      allow(SThreeResponseBuilder).to receive(:put) { |_k, body| written = body }

      expect(described_class.fetch(key, end_date) { [] }).to eq []
      expect(written).to eq '[]'

      allow(SThreeResponseBuilder).to receive(:response)
        .and_return(double(body: StringIO.new(written)))
      expect(described_class.fetch(key, end_date) { raise 'block should not run' }).to eq []
    end

    it 'does not store a truncated multi-page response' do
      truncated_page = double(
        column_headers: [GaResponseBuilder::Ga4Response::ColumnHeader.new('ga:eventLabel')],
        rows: rows,
        totals_for_all_results: {},
        total_results: 100_000
      )
      expect(SThreeResponseBuilder).not_to receive(:put)
      expect(described_class.fetch(key, end_date) { [truncated_page] }).to eq [truncated_page]
    end
  end
end
