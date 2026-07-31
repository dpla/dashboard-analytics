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
  end
end
