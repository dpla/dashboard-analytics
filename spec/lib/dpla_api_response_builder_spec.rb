require 'rails_helper'

describe DplaApiResponseBuilder do

  let(:response) { double }

  before do
    allow(DplaApiResponseBuilder).to receive(:get).and_return(response)
  end

  it 'retries twice if server error' do
    allow(response).to receive(:code).and_return(500)
    expect(DplaApiResponseBuilder).to receive(:get).exactly(3).times
    DplaApiResponseBuilder.new.hubs
  end

  it 'does not retry if no server error' do
    allow(response).to receive(:code).and_return(401)
    expect(DplaApiResponseBuilder).to receive(:get).exactly(1).times
    DplaApiResponseBuilder.new.hubs
  end
end
