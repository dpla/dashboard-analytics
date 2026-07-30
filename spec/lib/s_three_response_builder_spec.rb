require 'rails_helper'

describe SThreeResponseBuilder do
  describe '.cached_json' do
    let(:default) { { 'hubs' => {} } }

    before { Rails.cache.delete('test_json') }

    def fetch
      described_class.cached_json('some/key.json', cache_key: 'test_json', default: default)
    end

    it 'parses and caches the file for 24 hours' do
      allow(described_class).to receive(:response)
        .and_return(double(body: StringIO.new('{"hubs":{"foo":{}}}')))
      expect(Rails.cache).to receive(:write)
        .with('test_json', { 'hubs' => { 'foo' => {} } }, expires_in: 24.hours)
      expect(fetch).to eq('hubs' => { 'foo' => {} })
    end

    it 'caches the default for 24 hours when the file does not exist' do
      allow(described_class).to receive(:response)
        .and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'no such key'))
      expect(Rails.cache).to receive(:write).with('test_json', default, expires_in: 24.hours)
      expect(fetch).to eq default
    end

    it 'caches the default briefly on other failures, so they self-heal' do
      allow(described_class).to receive(:response).and_raise(Timeout::Error)
      expect(Rails.cache).to receive(:write).with('test_json', default, expires_in: 5.minutes)
      expect(fetch).to eq default
    end

    it 'reports a stale file so a stopped generator is noticed' do
      old = { 'generated_at' => 60.days.ago.iso8601, 'hubs' => {} }
      allow(described_class).to receive(:response)
        .and_return(double(body: StringIO.new(old.to_json)))
      expect(Sentry).to receive(:capture_message).with(a_string_including('stale'))
      fetch
    end

    it 'stays quiet for a fresh file' do
      fresh = { 'generated_at' => 3.days.ago.iso8601, 'hubs' => {} }
      allow(described_class).to receive(:response)
        .and_return(double(body: StringIO.new(fresh.to_json)))
      expect(Sentry).not_to receive(:capture_message)
      expect(fetch).to eq fresh
    end
  end
end
