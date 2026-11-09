require 'rails_helper'

describe ApiEventsPresenter do
  let(:column_header) { double(name: 'ga:eventLabel') }
  let(:ga_data) { double(column_headers: [column_header], rows: [], total_results: nil) }
  let(:ga_response) { double(response: ga_data, multi_page_response: []) }
  let(:presenter) { described_class.new(ga_response) }

  describe '#id' do
    it 'returns the id before the separator' do
      row = ['9ec935602492229f271b6611cdfd53a6 : Some Title']
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
    it 'returns the title after the separator' do
      row = ['some-id : My Title']
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
end
