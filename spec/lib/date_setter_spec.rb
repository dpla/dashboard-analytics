require 'rails_helper'

describe DateSetter do
  let(:host_class) do
    Class.new do
      include DateSetter
      attr_accessor :params

      def initialize(params = {})
        @params = params
      end
    end
  end
  let(:host) { host_class.new }

  before { allow(Date).to receive(:current).and_return(Date.new(2026, 7, 15)) }

  describe '#max_date' do
    it 'is the last day of the previous month' do
      expect(host.max_date).to eq Date.new(2026, 6, 30)
    end
  end

  describe '#assign_start_and_end_dates' do
    def assigned_dates
      host.assign_start_and_end_dates
      [host.instance_variable_get(:@start_date), host.instance_variable_get(:@end_date)]
    end

    it 'defaults to the last completed month when no params are given' do
      expect(assigned_dates).to eq [Date.new(2026, 6, 1), Date.new(2026, 6, 30)]
    end

    it 'respects a range of completed months' do
      host.params = { start_date: '2026-01', end_date: '2026-03' }
      expect(assigned_dates).to eq [Date.new(2026, 1, 1), Date.new(2026, 3, 31)]
    end

    it 'clamps an end date in the current month to the last completed month' do
      host.params = { start_date: '2026-01', end_date: '2026-07' }
      expect(assigned_dates).to eq [Date.new(2026, 1, 1), Date.new(2026, 6, 30)]
    end

    it 'clamps a range entirely in the current month to the last completed month' do
      host.params = { start_date: '2026-07', end_date: '2026-07' }
      expect(assigned_dates).to eq [Date.new(2026, 6, 1), Date.new(2026, 6, 30)]
    end
  end
end
