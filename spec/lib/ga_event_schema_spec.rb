require 'rails_helper'

describe GaEventSchema do
  describe '.eras' do
    let(:start_date) { Date.new(2025, 7, 1) }
    let(:end_date)   { Date.new(2026, 10, 31) }

    def eras
      described_class.eras(start_date, end_date).map { |e| [e.schema, e.start_date, e.end_date] }
    end

    it 'is all legacy for a range ending before the switch' do
      allow(DataWindow).to receive(:new_dimensions_date).and_return(Date.new(2026, 11, 1))
      expect(eras).to eq [[described_class::Legacy, start_date, end_date]]
    end

    it 'is all current for a range starting on or after the switch' do
      allow(DataWindow).to receive(:new_dimensions_date).and_return(start_date)
      expect(eras).to eq [[described_class::Current, start_date, end_date]]
    end

    it 'splits a range that crosses the switch, legacy first' do
      allow(DataWindow).to receive(:new_dimensions_date).and_return(Date.new(2026, 9, 12))
      expect(eras).to eq [
        [described_class::Legacy,  start_date, Date.new(2026, 9, 11)],
        [described_class::Current, Date.new(2026, 9, 12), end_date],
      ]
    end
  end

  describe described_class::Legacy do
    it 'filters a hub through event_category, leaving browsing out' do
      expect(described_class.hub_filters('Some Hub'))
        .to eq ['ga:eventCategory=@Some Hub', 'ga:eventCategory!@Browse']
    end

    it 'filters a contributor through the event name, cut as GA4 cut it' do
      long = 'University of Somewhere, School of Something Very Long'
      expect(described_class.hub_filters('Some Hub', long))
        .to include("ga:eventAction==#{long[0, 40]}")
    end

    it 'filters one event kind through the category prefix' do
      expect(described_class.event_filters('View Item', 'Some Hub'))
        .to eq ['ga:eventCategory==View Item : Some Hub']
    end

    it 'reads the event name off the category' do
      expect(described_class.event_name('View Item : Some Hub')).to eq 'View Item'
    end
  end

  describe described_class::Current do
    it 'filters a hub through partner and the counted event names' do
      expect(described_class.hub_filters('Some Hub')).to eq [
        'eventName=~^(item_view|exhibition_item_view|primary_source_view|click_through)$',
        'customEvent:partner==Some Hub',
      ]
    end

    it 'filters a contributor through its parameter, clipped as GA4 clips it' do
      long = 'L' * 120
      expect(described_class.hub_filters('Some Hub', long))
        .to include("customEvent:contributor==#{'L' * 100}")
    end

    it 'filters one event kind through its GA4 name' do
      expect(described_class.event_filters('Click Through', 'Some Hub', 'Some Library'))
        .to eq ['eventName==click_through', 'customEvent:partner==Some Hub',
                'customEvent:contributor==Some Library']
    end

    it 'maps GA4 names back to the dashboard labels' do
      expect(described_class.event_name('item_view')).to eq 'View Item'
      expect(described_class.event_name('browse_item')).to be_nil
      expect(described_class.event_name('(other)')).to be_nil
    end

    it 'folds id and title into the legacy label' do
      expect(described_class.item_row(%w[abc123 Title Library 4]))
        .to eq ['abc123 : Title', 'Library', '4']
    end
  end
end
