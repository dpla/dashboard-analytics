require 'rails_helper'

describe WebsiteEvents do
  let(:switch) { Date.new(2026, 9, 12) }

  let(:legacy_pages) do
    [cached_response(%w[ga:eventLabel ga:eventAction ga:totalEvents],
                     [['aaa : Old Title', 'Univ of Somewhere, School of Something Ve', '10'],
                      ['bbb : Only Old', 'Library B', '5']])]
  end
  let(:current_pages) do
    [cached_response(%w[customEvent:dpla_id customEvent:item_title customEvent:contributor ga:totalEvents],
                     [%w[ccc Only\ New Library\ C 9],
                      ['aaa', 'New Title', 'Univ of Somewhere, School of Something Very Long', '2']])]
  end

  def events(start_date: Date.new(2025, 7, 1), end_date: Date.new(2026, 10, 31), page: 1)
    described_class.build do |b|
      b.hub        = 'Some Hub'
      b.event_name = 'View Item'
      b.start_date = start_date
      b.end_date   = end_date
      b.page       = page
    end
  end

  before do
    stub_ga_cache_passthrough
    stub_new_dimensions_date(switch)
  end

  def stub_exports
    allow_any_instance_of(described_class).to receive(:builder_for) do |_events, era, **|
      pages = era.schema == GaEventSchema::Legacy ? legacy_pages : current_pages
      double(multi_page_response: pages)
    end
  end

  describe 'a range within one shape' do
    it 'asks GA4 for the page itself' do
      ga4_page = cached_response(%w[ga:eventLabel ga:eventAction ga:totalEvents],
                                 [['x : y', 'z', '1']], total: 70)
      expect_any_instance_of(described_class).to receive(:builder_for)
        .with(an_object_having_attributes(schema: GaEventSchema::Legacy), page: 2)
        .and_return(double(response: ga4_page))
      table = events(end_date: Date.new(2026, 8, 31), page: 2)
      expect(table.response.rows).to eq [['x : y', 'z', '1']]
      expect(table.response.total_results).to eq 70
    end

    it 'puts a current-shape page into the columns the table reads' do
      allow_any_instance_of(described_class).to receive(:builder_for)
        .and_return(double(response: current_pages.first, multi_page_response: current_pages))
      table = events(start_date: Date.new(2026, 10, 1))
      expect(table.response.column_headers.map(&:name)).to eq described_class::COLUMNS
      expect(table.response.rows.first).to eq ['ccc : Only New', 'Library C', '9']
      expect(table.multi_page_response.first.rows.last.first).to eq 'aaa : New Title'
    end
  end

  describe 'a range across both shapes' do
    before { stub_exports }

    it 'merges the exports into one table, most viewed first' do
      page = events.response
      expect(page.column_headers.map(&:name)).to eq described_class::COLUMNS
      expect(page.rows.map(&:first)).to eq ['aaa : New Title', 'ccc : Only New', 'bbb : Only Old']
      # aaa: 10 legacy + 2 current, with the current shape's longer names.
      expect(page.rows.first)
        .to eq ['aaa : New Title', 'Univ of Somewhere, School of Something Very Long', '12']
    end

    it 'pages the merged rows here' do
      stub_const('PaginationHelper::PAGE_SIZE', 2)
      expect(events(page: 2).response.rows.map(&:first)).to eq ['bbb : Only Old']
      expect(events(page: 2).response.total_results).to eq 3
    end

    it 'exports every merged row as one page' do
      pages = events.multi_page_response
      expect(pages.size).to eq 1
      expect(pages.first.rows.size).to eq 3
    end

    it 'caches each era export on its own dates, and nothing on the whole range' do
      keys = []
      allow(GaPersistentCache).to receive(:fetch_with_status) { |key, _end, &block| keys << key; [block.call, false] }
      allow(GaPersistentCache).to receive(:fetch) { |key, _end, &block| keys << key; block.call }
      events.response
      expect(keys).to contain_exactly(a_string_ending_with(':2025-07-01:2026-09-11:multi'),
                                      a_string_ending_with(':2026-09-12:2026-10-31:multi'))
    end

    it 'is nil when one export fails' do
      allow_any_instance_of(described_class).to receive(:builder_for)
        .and_raise(StandardError, 'GA4 is down')
      expect(events.response).to be_nil
      expect(events.multi_page_response).to eq []
    end
  end
end
