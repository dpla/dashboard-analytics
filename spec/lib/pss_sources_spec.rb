require 'rails_helper'

describe PssSources do
  let(:json) do
    {
      'generated_at' => '2026-09-01T00:00:00Z',
      'sources' => {
        'the-new-deal/12' => {
          'item' => 'abc123', 'hub' => 'HathiTrust',
          'contributor' => 'University of Michigan', 'title' => 'A Poster'
        },
        'the-new-deal/13' => { 'item' => 'def456', 'title' => 'Gone From The Index' }
      }
    }.to_json
  end
  let(:s3_object) { double(body: StringIO.new(json)) }

  before do
    described_class.instance_variable_set(:@expires_at, nil)
    allow(SThreeResponseBuilder).to receive(:response)
      .with(described_class::KEY).and_return(s3_object)
  end

  describe '.participant?' do
    it 'is true for a hub holding a source' do
      expect(described_class.participant?('HathiTrust')).to be true
    end

    it 'is true for the contributor holding it' do
      expect(described_class.participant?('HathiTrust', 'University of Michigan'))
        .to be true
    end

    it 'is false for another contributor at the same hub' do
      expect(described_class.participant?('HathiTrust', 'Cornell University'))
        .to be false
    end

    it 'is false for a hub with nothing' do
      expect(described_class.participant?('Some Other Hub')).to be false
    end

    it 'skips a malformed entry instead of raising' do
      allow(s3_object).to receive(:body).and_return(StringIO.new(
        { 'sources' => { 'the-new-deal/12' => nil } }.to_json))
      expect(described_class.participant?('HathiTrust')).to be false
    end

    it 'is false when the map is missing' do
      allow(SThreeResponseBuilder).to receive(:response)
        .and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'no such key'))
      expect(described_class.participant?('HathiTrust')).to be false
    end
  end

  describe '.sources' do
    it 'returns the path => source mapping from S3' do
      expect(described_class.sources.keys)
        .to contain_exactly('the-new-deal/12', 'the-new-deal/13')
      expect(described_class.sources['the-new-deal/12']['hub']).to eq 'HathiTrust'
    end

  end
end
