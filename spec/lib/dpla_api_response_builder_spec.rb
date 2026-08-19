require 'rails_helper'

describe DplaApiResponseBuilder do

  let(:builder) { described_class.new }
  let(:response) { double }

  before do
    allow(described_class).to receive(:get).and_return(response)
    allow(builder).to receive(:sleep)
  end

  it 'retries twice if server error' do
    allow(response).to receive(:code).and_return(500)
    expect(described_class).to receive(:get).exactly(3).times
    builder.data_providers_for_items(['abc123'])
  end

  it 'does not retry if no server error' do
    allow(response).to receive(:code).and_return(401)
    expect(described_class).to receive(:get).exactly(1).times
    builder.data_providers_for_items(['abc123'])
  end

  it 'maps docs to item id => dataProvider name, omitting items without a name' do
    body = { 'docs' => [
      { 'id' => 'abc123', 'dataProvider' => { 'name' => 'Some Institution' } },
      { 'id' => 'def456' }
    ] }
    allow(response).to receive(:code).and_return(200)
    allow(response).to receive(:to_json).and_return(body.to_json)
    expect(builder.data_providers_for_items(%w[abc123 def456]))
      .to eq('abc123' => 'Some Institution')
  end

  describe '#curated_breakdown' do
    def stub_facets(field, terms)
      body = { 'facets' => { field => { 'terms' => terms } } }
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:body).and_return(body.to_json)
    end

    it 'maps facet terms to slug => item count' do
      stub_facets('exhibitions',
                  [{ 'term' => 'erie-canal', 'count' => 7 },
                   { 'term' => 'race-to-the-moon', 'count' => 3 }])
      expect(builder.curated_breakdown(:exhibitions, 'HathiTrust'))
        .to eq('erie-canal' => 7, 'race-to-the-moon' => 3)
    end

    it 'is empty when the institution has no items in the curated content' do
      stub_facets('exhibitions', [])
      expect(builder.curated_breakdown(:exhibitions, 'Texas Digital Library')).to eq({})
    end

    it 'facets the field for the given kind, scoped to the institution' do
      stub_facets('primarySourceSets', [])
      expect(described_class).to receive(:get).with(
        '/items',
        hash_including(
          query: hash_including(
            'facets' => 'primarySourceSets',
            'provider.name' => '"HathiTrust"',
            'dataProvider.name' => '"University of Michigan"',
            'page_size' => 0
          )
        )
      ).and_return(response)
      builder.curated_breakdown(:primary_source_sets, 'HathiTrust', 'University of Michigan')
    end

    it 'is nil on a non-200 response so callers can fail open' do
      allow(response).to receive(:code).and_return(500)
      expect(builder.curated_breakdown(:exhibitions, 'HathiTrust')).to be_nil
    end

    it 'is nil when the request raises' do
      allow(described_class).to receive(:get).and_raise(Net::OpenTimeout)
      expect(builder.curated_breakdown(:exhibitions, 'HathiTrust')).to be_nil
    end

    it 'makes a single attempt with no retries' do
      allow(response).to receive(:code).and_return(500)
      expect(described_class).to receive(:get).exactly(1).times.and_return(response)
      builder.curated_breakdown(:exhibitions, 'HathiTrust')
    end
  end

  describe '#curated_memberships_for_items' do
    def stub_docs(docs)
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:body).and_return({ 'docs' => docs }.to_json)
    end

    it 'maps item ids to slugs, handling both array and bare-string fields' do
      stub_docs([{ 'id' => 'aaa', 'exhibitions' => %w[erie-canal activism] },
                 { 'id' => 'bbb', 'exhibitions' => 'race-to-the-moon' }])
      expect(builder.curated_memberships_for_items(:exhibitions, %w[aaa bbb]))
        .to eq('aaa' => %w[erie-canal activism], 'bbb' => %w[race-to-the-moon])
    end

    it 'omits items with no membership' do
      stub_docs([{ 'id' => 'aaa' }])
      expect(builder.curated_memberships_for_items(:exhibitions, %w[aaa ded]))
        .to eq({})
    end

    it 'queries the search endpoint with an OR list and slim fields' do
      stub_docs([])
      expect(described_class).to receive(:get).with(
        '/items',
        hash_including(
          query: hash_including(
            'id' => 'aaa OR bbb',
            'fields' => 'id,primarySourceSets'
          )
        )
      ).and_return(response)
      builder.curated_memberships_for_items(:primary_source_sets, %w[aaa bbb])
    end

    it 'is empty on a non-200 response' do
      allow(response).to receive(:code).and_return(500)
      expect(builder.curated_memberships_for_items(:exhibitions, %w[aaa])).to eq({})
    end

    it 'splits ids into batches that fit the 200-character parameter cap' do
      stub_docs([])
      ids = Array.new(12) { |i| format('%032x', i) }
      expect(described_class).to receive(:get).exactly(3).times.and_return(response)
      builder.curated_memberships_for_items(:exhibitions, ids)
    end

    it 'is empty when the request raises' do
      allow(described_class).to receive(:get).and_raise(Net::OpenTimeout)
      expect(builder.curated_memberships_for_items(:exhibitions, %w[aaa])).to eq({})
    end
  end
end
