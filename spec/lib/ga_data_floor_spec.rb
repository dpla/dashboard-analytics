require 'rails_helper'

describe GaDataFloor do
  let(:host_class) do
    Class.new do
      # Stand in for the one controller method the concerns call on include.
      def self.helper_method(*); end

      include DateSetter
      include GaDataFloor
      attr_accessor :params

      def initialize(params = {})
        @params = params
      end
    end
  end
  let(:host) { host_class.new({ hub_id: 'foo' }) }

  before { allow(Date).to receive(:current).and_return(Date.new(2026, 7, 15)) }

  def stub_earliest(date)
    activity = instance_double(WebsiteActivityMonths, earliest_month: date)
    allow(WebsiteActivityMonths).to receive(:build).and_return(activity)
  end

  describe '#picker_min_date' do
    it 'is the earliest GA4 month with data' do
      stub_earliest(Date.new(2025, 5, 1))
      expect(host.picker_min_date).to eq Date.new(2025, 5, 1)
    end

    it 'falls back to min_date when the earliest month is unknown' do
      stub_earliest(nil)
      expect(host.picker_min_date).to eq host.min_date
    end

    it 'never starts after the last completed month' do
      stub_earliest(Date.new(2026, 7, 1))
      expect(host.picker_min_date).to eq Date.new(2026, 6, 1)
    end
  end

  describe '#ga4_earliest_month' do
    # Settling days: scan must end in the prior month to match a stored entry.
    it 'ends the scan at the newest settled day' do
      allow(Date).to receive(:current).and_return(Date.new(2026, 7, 2))

      scan_end = nil
      allow(WebsiteActivityMonths).to receive(:build) do |&config|
        builder = WebsiteActivityMonths.new
        config.call(builder)
        scan_end = builder.instance_variable_get(:@end_date)
        instance_double(WebsiteActivityMonths, earliest_month: nil)
      end

      host.ga4_earliest_month
      expect(scan_end).to eq Date.new(2026, 5, 31)
    end
  end
end
