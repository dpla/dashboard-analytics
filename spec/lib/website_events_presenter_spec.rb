require 'rails_helper'

describe WebsiteEventsPresenter do
  let(:column_header) { double(name: 'ga:eventLabel') }
  let(:ga_data) { double(column_headers: [column_header], rows: [], total_results: nil) }
  let(:ga_response) { double(response: ga_data, multi_page_response: []) }
  let(:presenter) { described_class.new(ga_response) }

  describe '#id' do
    it 'strips CRLF from item id' do
      row = ["9ec935602492229f271b6611cdfd53a6\r\n : Some Title"]
      expect(presenter.id(row)).to eq '9ec935602492229f271b6611cdfd53a6'
    end

    it 'returns nil when label is nil' do
      row = [nil]
      expect(presenter.id(row)).to be_nil
    end

    it 'returns nil when the label column is missing' do
      allow(column_header).to receive(:name).and_return('ga:other')
      expect(presenter.id(['some-id : Title'])).to be_nil
    end
  end

  describe '#title' do
    it 'strips CRLF from title' do
      row = ["some-id : My Title\r\n"]
      expect(presenter.title(row)).to eq 'My Title'
    end

    it 'returns nil when label is nil' do
      row = [nil]
      expect(presenter.title(row)).to be_nil
    end

    it 'keeps a title containing the separator intact' do
      row = ['some-id : Blueberry : Pie']
      expect(presenter.title(row)).to eq 'Blueberry : Pie'
    end
  end

  describe 'contributor resolution' do
    let(:column_header) do
      [double(name: 'ga:eventLabel'), double(name: 'ga:eventAction'),
       double(name: 'ga:totalEvents')]
    end
    let(:row) { ['abc123 : Some Title', 'Truncated Institution', '42'] }
    let(:ga_data) { double(column_headers: column_header, rows: [row], total_results: 1) }
    let(:ga_response) do
      double(response: ga_data, multi_page_response: [ga_data], event_name: 'Click Through')
    end

    describe '#contributor' do
      it 'resolves names from the item_data_providers cache without calling the API' do
        allow(ItemDataProviders).to receive(:items)
          .and_return('abc123' => 'Full Institution Name')
        expect(DplaApiResponseBuilder).not_to receive(:new)
        expect(presenter.contributor(row)).to eq 'Full Institution Name'
      end

      it 'falls back to the live API only for ids the cache does not cover' do
        allow(ItemDataProviders).to receive(:items).and_return({})
        api = instance_double(DplaApiResponseBuilder)
        allow(DplaApiResponseBuilder).to receive(:new).and_return(api)
        allow(api).to receive(:data_providers_for_items).with(['abc123'])
          .and_return('abc123' => 'API Institution Name')
        expect(presenter.contributor(row)).to eq 'API Institution Name'
      end

      it 'falls back to the GA4 eventAction when the id resolves nowhere' do
        allow(ItemDataProviders).to receive(:items).and_return({})
        api = instance_double(DplaApiResponseBuilder)
        allow(DplaApiResponseBuilder).to receive(:new).and_return(api)
        allow(api).to receive(:data_providers_for_items).and_return({})
        expect(presenter.contributor(row)).to eq 'Truncated Institution'
      end
    end

    describe '#to_csv' do
      it 'resolves contributor names per export page from the cache' do
        allow(ItemDataProviders).to receive(:items)
          .and_return('abc123' => 'Full Institution Name')
        expect(DplaApiResponseBuilder).not_to receive(:new)
        expect(presenter.to_csv).to include 'Full Institution Name'
      end
    end
  end

  describe 'curated content membership' do
    let(:column_header) { [double(name: 'ga:eventLabel')] }
    let(:row) { ['abc123 : Some Title'] }
    let(:ga_data) { double(column_headers: column_header, rows: [row], total_results: 1) }
    let(:ga_response) do
      double(response: ga_data, multi_page_response: [], event_name: event_name)
    end

    context 'on an exhibition views table' do
      let(:event_name) { 'View Exhibition Item' }

      it 'resolves slugs for the row through one batched lookup' do
        api = instance_double(DplaApiResponseBuilder)
        allow(DplaApiResponseBuilder).to receive(:new).and_return(api)
        allow(api).to receive(:curated_memberships_for_items)
          .with(:exhibitions, ['abc123'])
          .and_return('abc123' => ['erie-canal'])
        expect(presenter.membership_kind).to eq :exhibitions
        expect(presenter.memberships(row)).to eq ['erie-canal']
      end
    end

    context 'on a table that is not curated content' do
      let(:event_name) { 'View Item' }

      it 'is empty and never calls the API' do
        expect(DplaApiResponseBuilder).not_to receive(:new)
        expect(presenter.membership_kind).to be_nil
        expect(presenter.memberships(row)).to eq []
      end
    end
  end
end
