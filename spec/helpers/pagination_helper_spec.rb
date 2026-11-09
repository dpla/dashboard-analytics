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

  describe '#page_links' do
    it 'lists every page when they all fit' do
      expect(helper.page_links(5, 3)).to eq [1, 2, 3, 4, 5]
    end

    it 'keeps the first and last page and gaps the rest' do
      expect(helper.page_links(40, 20)).to eq [1, nil, 18, 19, 20, 21, 22, nil, 40]
    end

    it 'has no leading gap near the start' do
      expect(helper.page_links(40, 2)).to eq [1, 2, 3, 4, nil, 40]
    end

    it 'has no trailing gap near the end' do
      expect(helper.page_links(40, 39)).to eq [1, nil, 37, 38, 39, 40]
    end

    it 'clamps a page past the end' do
      expect(helper.page_links(5, 99)).to eq [1, 2, 3, 4, 5]
    end

    it 'shows a lone skipped page rather than an ellipsis for it' do
      expect(helper.page_links(8, 5)).to eq [1, 2, 3, 4, 5, 6, 7, 8]
    end
  end

  describe '#pagination_form_target' do
    it 'carries the other query params so the jump form keeps context' do
      page_url = ->(page) do
        "/hubs/HathiTrust/events/view_exhibit?start_date=2025-07&page=#{page}"
      end
      path, carried = helper.pagination_form_target(page_url)
      expect(path).to eq "/hubs/HathiTrust/events/view_exhibit"
      expect(carried).to eq("start_date" => "2025-07")
    end
  end
end
