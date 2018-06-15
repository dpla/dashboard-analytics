require 'rails_helper'

describe GaResponseBuilder do

  let(:start_date) { "2018-01-01" }
  let(:end_date) { "2018-01-31" }
  let(:gaResponseBuilder) { GaResponseBuilder.new(start_date, end_date) }

  # Stub Google::Auth::ServiceAccountCredentials
  let(:credentials) { double }

  before do
    GaResponseBuilder.class_variable_set :@@authorizer, credentials
  end

  it 'returns start date' do
    expect(gaResponseBuilder.start_date).to eq start_date
  end

  it 'returns end date' do
    expect(gaResponseBuilder.end_date).to eq end_date
  end

  it 'returns current access token' do
    allow(credentials).to receive(:expired?).and_return(false)
    allow(credentials).to receive(:access_token).and_return("abc")
    expect(gaResponseBuilder.token).to eq "abc"
  end

  it 'renews access token if expired' do
    allow(credentials).to receive(:expired?).and_return(true)
    allow(credentials).to receive(:access_token).and_return("abc")
    expect(credentials).to receive(:fetch_access_token!)
    gaResponseBuilder.token
  end

  it 'fetches access token if one does not yet exist' do
    allow(credentials).to receive(:access_token).and_return(nil)
    expect(credentials).to receive(:fetch_access_token!)
    gaResponseBuilder.token
  end

end