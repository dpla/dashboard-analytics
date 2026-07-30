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
end
