require 'rails_helper'

describe ItemDataProviders do
  let(:json) do
    {
      'generated_at' => '2026-05-09T19:11:52+00:00',
      'items' => {
        'abc123' => 'California Digital Library',
        'def456' => 'Mountain West Digital Library'
      }
    }.to_json
  end
  let(:s3_object) { double(body: StringIO.new(json)) }

  before do
    Rails.cache.delete(described_class::CACHE_KEY)
    allow(SThreeResponseBuilder).to receive(:response)
      .with(described_class::KEY).and_return(s3_object)
  end

  describe '.items' do
    it 'returns the id => name mapping from S3' do
      expect(described_class.items)
        .to eq('abc123' => 'California Digital Library',
               'def456' => 'Mountain West Digital Library')
    end

    it 'returns an empty hash when the file does not exist in S3' do
      allow(SThreeResponseBuilder).to receive(:response)
        .and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'no such key'))
      expect(described_class.items).to eq({})
    end

    it 'returns an empty hash when the file is not valid JSON' do
      allow(s3_object).to receive(:body).and_return(StringIO.new('not json'))
      expect(described_class.items).to eq({})
    end
  end
end
