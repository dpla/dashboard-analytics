require 'rails_helper'

describe PaginationHelper, type: :helper do

  describe '#current_page' do
    it 'defaults to 1 when no page param is present' do
      expect(helper.current_page).to eq 1
    end

    it 'reads the page param' do
      controller.params[:page] = '3'
      expect(helper.current_page).to eq 3
    end

    it 'clamps non-numeric and negative values to 1' do
      controller.params[:page] = 'abc'
      expect(helper.current_page).to eq 1
      controller.params[:page] = '-2'
      expect(helper.current_page).to eq 1
    end
  end

  describe '#page_opts' do
    it 'is empty on page 1 so URLs stay clean' do
      expect(helper.page_opts).to eq({})
    end

    it 'carries the current page' do
      controller.params[:page] = '2'
      expect(helper.page_opts).to eq({ page: 2 })
    end
  end

  describe '#page_window' do
    it 'formats the visible range' do
      controller.params[:page] = '2'
      expect(helper.page_window(120, 50, 'items')).to eq 'Showing 51-100 of 120 items.'
    end

    it 'handles an empty page' do
      expect(helper.page_window(120, 0, 'items')).to eq 'Showing 0 of 120 items.'
    end

    it 'delimits large numbers' do
      expect(helper.page_window(2660, 50, 'items')).to eq 'Showing 1-50 of 2,660 items.'
    end
  end

  describe '#paginate' do
    let(:items) { (1..120).to_a }

    it 'returns the first page by default' do
      expect(helper.paginate(items)).to eq (1..50).to_a
    end

    it 'returns the slice for the current page' do
      controller.params[:page] = '3'
      expect(helper.paginate(items)).to eq (101..120).to_a
    end

    it 'returns an empty array beyond the last page' do
      controller.params[:page] = '4'
      expect(helper.paginate(items)).to eq []
    end
  end
end
