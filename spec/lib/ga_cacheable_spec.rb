require 'rails_helper'

describe GaCacheable do
  let(:host_class) do
    Class.new do
      include GaCacheable

      def self.name
        'FakeGaWrapper'
      end

      def initialize(end_date)
        @hub = 'Some Hub'
        @end_date = end_date
      end
    end
  end
  let(:completed_month) { Date.new(2026, 6, 30) }
  let(:host) { host_class.new(completed_month) }

  before do
    allow(Date).to receive(:current).and_return(Date.new(2026, 7, 15))
    Rails.cache.clear
  end

  describe '#fetch_cached' do
    it 'delegates to the permanent store with the key and end date' do
      expect(GaPersistentCache).to receive(:fetch_with_status)
        .with(a_string_including('fake_ga_wrapper'), completed_month)
        .and_return([:cached, true])
      expect(host.send(:fetch_cached) { :live }).to eq :cached
    end

    it 'appends the suffix to the cache key' do
      expect(GaPersistentCache).to receive(:fetch_with_status)
        .with(a_string_ending_with(':page1'), completed_month).and_return([:cached, true])
      host.send(:fetch_cached, 'page1') { :live }
    end

    it 'keeps an entry the permanent store holds without expiry' do
      allow(GaPersistentCache).to receive(:fetch_with_status).and_return([:cached, true])
      expect(Rails.cache).to receive(:write).with(anything, :cached, expires_in: nil)
      host.send(:fetch_cached) { :live }
    end

    it 'expires an entry the permanent store declined' do
      # A truncated export or a failed S3 write must not be pinned in memory:
      # a later max_pages increase has to take effect.
      allow(GaPersistentCache).to receive(:fetch_with_status).and_return([:live, false])
      expect(Rails.cache).to receive(:write)
        .with(anything, :live, expires_in: GaCacheable::CACHE_TTL)
      expect(host.send(:fetch_cached) { :live }).to eq :live
    end

    it 'serves a memory hit without touching the permanent store' do
      allow(GaPersistentCache).to receive(:fetch_with_status).and_return([:cached, true])
      host.send(:fetch_cached) { :live }
      expect(GaPersistentCache).not_to receive(:fetch_with_status)
      expect(host.send(:fetch_cached) { :live }).to eq :cached
    end

    it 'skips Rails.cache when memory is false and S3 serves the response' do
      allow(GaPersistentCache).to receive(:fetch).and_return(:cached)
      expect(Rails.cache).not_to receive(:fetch)
      expect(host.send(:fetch_cached, 'multi', memory: false) { :live }).to eq :cached
    end

    it 'keeps a short-lived copy when the permanent store declines the result' do
      allow(GaPersistentCache).to receive(:fetch) { |_key, _date, &blk| blk.call }
      expect(Rails.cache).to receive(:fetch)
        .with(anything, expires_in: GaCacheable::CACHE_TTL).and_call_original
      expect(host.send(:fetch_cached, 'multi', memory: false) { :live }).to eq :live
    end

    it 'falls back to a short-lived memory entry while the range is settling' do
      settling_host = host_class.new(Date.new(2026, 7, 10))
      expect(Rails.cache).to receive(:write)
        .with(anything, :live, expires_in: GaCacheable::CACHE_TTL).and_call_original
      expect(settling_host.send(:fetch_cached, 'multi', memory: false) { :live }).to eq :live
    end
  end

  describe 'schema version' do
    # Guards a store that outlives a deploy: bumping the S3 schema must not
    # leave Rails.cache serving the old shape.
    it 'reads a new Rails entry after a version bump' do
      allow(GaPersistentCache).to receive(:cacheable?).and_return(false)
      allow(GaPersistentCache).to receive(:fetch) { |_key, _date, &blk| blk.call }

      expect(host.send(:fetch_cached) { :v1 }).to eq :v1
      expect(host.send(:fetch_cached) { :never_called }).to eq :v1

      stub_const('GaPersistentCache::SCHEMA_VERSION', 'v2')
      expect(host.send(:fetch_cached) { :v2 }).to eq :v2
    end
  end

  describe '#prefetch' do
    it 'writes to Rails.cache and the permanent store' do
      expect(GaPersistentCache).to receive(:write)
        .with(a_string_including('fake_ga_wrapper'), :response, completed_month)
      expect(Rails.cache).to receive(:write)
        .with(a_string_including('fake_ga_wrapper'), :response,
              expires_in: GaCacheable::CACHE_TTL)
      host.prefetch(:response)
      expect(host.instance_variable_get(:@response)).to eq :response
    end

    it 'holds the compact stored form, without expiry, when one was stored' do
      allow(GaPersistentCache).to receive(:write).and_return(:compact)
      expect(Rails.cache).to receive(:write).with(anything, :compact, expires_in: nil)
      host.prefetch(:response)
      expect(host.instance_variable_get(:@response)).to eq :compact
    end

    it 'ignores nil responses instead of caching them' do
      expect(Rails.cache).not_to receive(:write)
      expect(GaPersistentCache).not_to receive(:write)
      host.prefetch(nil)
      expect(host.instance_variable_get(:@response)).to be_nil
    end
  end
end
