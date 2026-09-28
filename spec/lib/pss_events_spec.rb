require 'rails_helper'

describe PssEvents do
  let(:sources) do
    {
      'the-new-deal/12'   => { 'item' => 'aaa', 'hub' => 'HathiTrust',
                               'contributor' => 'University of Michigan',
                               'title' => 'A Poster' },
      'the-new-deal/13'   => { 'item' => 'bbb', 'hub' => 'HathiTrust',
                               'contributor' => 'Cornell University',
                               'title' => 'A Letter' },
      'the-great-war/14'  => { 'item' => 'aaa', 'hub' => 'HathiTrust',
                               'contributor' => 'University of Michigan',
                               'title' => 'A Poster' },
      'the-new-deal/15'   => { 'item' => 'ccc', 'hub' => 'Digital Commonwealth',
                               'contributor' => 'Boston Public Library',
                               'title' => 'A Map' },
      # Left the index, so no hub to attribute it to.
      'the-new-deal/16'   => { 'item' => 'ddd', 'title' => 'A Ghost' }
    }
  end

  let(:ga_rows) do
    [
      ['/primary-source-sets/the-new-deal/sources/12',  '100'],
      ['/primary-source-sets/the-new-deal/sources/13',  '300'],
      ['/primary-source-sets/the-great-war/sources/14', '50'],
      ['/primary-source-sets/the-new-deal/sources/15',  '900'],
      ['/primary-source-sets/the-new-deal/sources/16',  '700'],
      # The first is not a source page. The second is not in the map.
      ['/primary-source-sets/the-new-deal',             '400'],
      ['/primary-source-sets/the-new-deal/sources/99',  '20']
    ]
  end

  let(:ga_response) { cached_response(%w[pagePath screenPageViews], ga_rows) }

  def events(hub: 'HathiTrust', contributor: nil, page: nil)
    described_class.build do |b|
      b.hub         = hub
      b.contributor = contributor
      b.start_date  = Date.new(2023, 4, 1)
      b.end_date    = Date.new(2026, 8, 31)
      b.page        = page
    end
  end

  before do
    stub_ga_cache_passthrough
    allow(PssSources).to receive(:sources).and_return(sources)
    allow_any_instance_of(described_class)
      .to receive(:page_views_builder).and_return(double(multi_page_response: [ga_response]))
  end

  describe '#response' do
    it 'keeps only this hub, most viewed first, one row per item' do
      rows = events.response.rows
      expect(rows.map { |r| r[0] }).to eq ['bbb : A Letter', 'aaa : A Poster']
      # aaa is source 12 (100) and source 14 (50).
      expect(rows.last).to eq ['aaa : A Poster', 'University of Michigan', '150']
    end

    it 'drops items that have left the index' do
      expect(events.response.rows.map { |r| r[0] }).not_to include(a_string_starting_with('ddd'))
    end

    it 'drops paths the source map does not know' do
      expect(events.response.rows.sum { |r| r[2].to_i }).to eq 450
    end

    it 'narrows to one contributor' do
      rows = events(contributor: 'Cornell University').response.rows
      expect(rows.map { |r| r[0] }).to eq ['bbb : A Letter']
    end

    it 'reports the columns the events table reads' do
      expect(events.response.column_headers.map(&:name))
        .to eq %w[ga:eventLabel ga:eventAction ga:totalEvents]
    end

    it 'pages the rows but counts them all' do
      stub_const("PaginationHelper::PAGE_SIZE", 1)
      page = events(page: 2).response
      expect(page.rows.map { |r| r[0] }).to eq ['aaa : A Poster']
      expect(page.total_results).to eq 2
    end
  end

  describe '#multi_page_response' do
    it 'holds every row, ignoring the page' do
      stub_const("PaginationHelper::PAGE_SIZE", 1)
      pages = events(page: 1).multi_page_response
      expect(pages.size).to eq 1
      expect(pages.first.rows.size).to eq 2
    end
  end

  describe '#total_views' do
    it 'totals the hub across every source' do
      expect(events.total_views).to eq 450
    end
  end

  describe 'when the GA4 call fails' do
    before do
      allow_any_instance_of(described_class).to receive(:page_views_builder)
        .and_raise(StandardError, 'GA4 is down')
    end

    it 'returns nil, [] and 0 rather than raising' do
      expect(events.response).to be_nil
      expect(events.multi_page_response).to eq []
      expect(events.total_views).to eq 0
    end
  end

  describe '#memberships' do
    it 'names the sets each item was viewed under' do
      expect(events.memberships).to eq('aaa' => %w[the-new-deal the-great-war],
                                       'bbb' => %w[the-new-deal])
    end
  end

  describe 'the date range' do
    it 'clamps the start to the first month with page views' do
      early = events
      early.start_date = Date.new(2018, 1, 1)
      expect(early.start_date).to eq DataWindow.pss_min_date
      early.start_date = Date.new(2025, 7, 1)
      expect(early.start_date).to eq Date.new(2025, 7, 1)
    end

    it 'asks GA4 nothing for a range ending before the first page views' do
      expect(GaResponseBuilder).not_to receive(:build)
      early = events
      early.start_date = Date.new(2020, 1, 1)
      early.end_date   = Date.new(2020, 12, 31)
      expect(early.total_views).to eq 0
      expect(early.response.rows).to eq []
    end
  end

  describe 'caching' do
    it 'keys on the date range alone, so one report serves every hub' do
      key = events.send(:cache_key)
      expect(key).to eq events(hub: 'Digital Commonwealth', contributor: 'X').send(:cache_key)
      expect(key).to include('pss_events', '2023-04-01', '2026-08-31')
      expect(key).not_to include('HathiTrust')
    end
  end

  describe 'the GA4 query' do
    it 'asks for source page views only' do
      allow_any_instance_of(described_class).to receive(:page_views_builder).and_call_original
      builder = double(multi_page_response: [ga_response])
      expect(GaResponseBuilder).to receive(:build) do |&block|
        spy = double.as_null_object
        expect(spy).to receive(:metrics=).with(%w[screenPageViews])
        expect(spy).to receive(:dimensions=).with(%w[pagePath])
        expect(spy).to receive(:filters=)
          .with(["pagePath=~#{described_class::PATH_PATTERN}"])
        block.call(spy)
        builder
      end
      events.response
    end
  end
end
