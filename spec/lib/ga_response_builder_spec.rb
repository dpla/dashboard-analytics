require 'rails_helper'

describe GaResponseBuilder do

  describe '.read_timeout_sec' do
    def set_env(value)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GA4_READ_TIMEOUT_SEC").and_return(value)
    end

    it 'uses the default when the env var is unset' do
      set_env(nil)
      expect(described_class.read_timeout_sec).to eq described_class::GA4_READ_TIMEOUT_SEC
    end

    it 'uses a positive integer override' do
      set_env("120")
      expect(described_class.read_timeout_sec).to eq 120
    end

    it 'falls back to the default for blank, non-numeric, and non-positive values' do
      ["", "  ", "abc", "0", "-5", "12.5"].each do |value|
        set_env(value)
        expect(described_class.read_timeout_sec).to eq described_class::GA4_READ_TIMEOUT_SEC
      end
    end

    it 'reaches the GA client as the read timeout' do
      set_env("")
      expect(described_class.new.analytics.client_options.read_timeout_sec)
        .to eq described_class::GA4_READ_TIMEOUT_SEC
    end
  end

  describe 'pagination parameters' do
    let(:builder) do
      described_class.new.tap do |b|
        b.metrics    = %w(ga:totalEvents)
        b.dimensions = %w(ga:eventLabel)
      end
    end

    it 'defaults to the full GA4 page limit and no offset' do
      request = builder.build_request(builder.offset)
      expect(request.limit).to eq described_class::DEFAULT_PAGE_LIMIT
      expect(request.offset).to eq 0
    end

    it 'converts a 1-based start_index to a 0-based offset' do
      builder.start_index = 51
      expect(builder.offset).to eq 50
    end

    it 'clamps start_index below 1 to offset 0' do
      builder.start_index = 0
      expect(builder.offset).to eq 0
    end

    it 'sets offset and limit from a 1-based page number' do
      builder.page = 3
      request = builder.build_request(builder.offset)
      expect(request.offset).to eq 2 * PaginationHelper::PAGE_SIZE
      expect(request.limit).to eq PaginationHelper::PAGE_SIZE
    end

    it 'ignores a nil page' do
      builder.page = nil
      expect(builder.build_request(builder.offset).limit)
        .to eq described_class::DEFAULT_PAGE_LIMIT
    end

    it 'requests full-size pages for multi-page exports regardless of display page' do
      builder.page = 2
      allow(builder).to receive(:response).and_return(nil)
      builder.multi_page_response
      expect(builder).to have_received(:response)
        .with(offset: 0, limit: described_class::DEFAULT_PAGE_LIMIT)
    end
  end
end
