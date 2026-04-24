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
  end
end
