require 'rails_helper'

describe DataWindow do
  describe '.new_dimensions_date' do
    it 'reads the day-level setting' do
      allow(Settings).to receive(:new_dimensions_date)
        .and_return(double(year: '2026', month: '09', day: '12'))
      expect(described_class.new_dimensions_date).to eq Date.new(2026, 9, 12)
    end
  end
end
