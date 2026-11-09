require 'rails_helper'

describe WarmComparisonCacheJob do
  describe '#warm_hub' do
    it 'reports every thread failure, not just the raised one' do
      job = described_class.new
      batch_error = StandardError.new('batch failed')
      table_error = StandardError.new('tables failed')
      allow(GaAuthorizer).to receive(:credentials).and_return(double)
      allow(GaResponseBuilder).to receive(:batch_responses).and_raise(batch_error)
      allow(job).to receive(:warm_event_tables).and_raise(table_error)

      # The batch error propagates to the caller's rescue; the coinciding
      # event-table error must still reach Sentry.
      expect(Sentry).to receive(:capture_exception).with(table_error)
      expect {
        job.send(:warm_hub, 'Some Hub', Date.new(2026, 1, 1), Date.new(2026, 6, 30))
      }.to raise_error('batch failed')
    end

    it 'batches one report per era and stores each under its era' do
      job = described_class.new
      allow(GaAuthorizer).to receive(:credentials).and_return(double)
      allow(job).to receive(:warm_event_tables).and_return(0)
      # The switch falls inside the all-time range, before last month.
      allow(DataWindow).to receive(:new_dimensions_date).and_return(Date.new(2026, 3, 12))

      batched = nil
      allow(GaResponseBuilder).to receive(:batch_responses) do |builders|
        batched = builders.size
        builders.map { :response }
      end
      prefetched = Hash.new { |h, k| h[k] = [] }
      [WebsiteOverviewByContributor, WebsiteEventsByContributor,
       WebsiteOverview, WebsiteEventTotals, WebsiteActivityMonths].each do |klass|
        allow_any_instance_of(klass).to receive(:prefetch) do |section, era, response|
          prefetched[klass] << [era.schema, era.start_date, era.end_date, response]
        end
      end

      job.send(:warm_hub, 'Some Hub', Date.new(2026, 1, 1), Date.new(2026, 6, 30))

      expect(batched).to eq 8
      expect(prefetched[WebsiteOverview]).to eq [
        [GaEventSchema::Legacy,  Date.new(2026, 1, 1),  Date.new(2026, 3, 11), :response],
        [GaEventSchema::Current, Date.new(2026, 3, 12), Date.new(2026, 6, 30), :response],
      ]
      expect(prefetched[WebsiteEventsByContributor]).to eq [
        [GaEventSchema::Current, Date.new(2026, 6, 1), Date.new(2026, 6, 30), :response],
      ]
    end
  end
end
