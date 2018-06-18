require 'rails_helper'

describe GaAuthorizer do

  # Stub Google::Auth::ServiceAccountCredentials
  let(:credentials) { double }

  before do
    GaAuthorizer.class_variable_set :@@authorizer, credentials
  end

  it 'returns current access token' do
    allow(credentials).to receive(:expired?).and_return(false)
    allow(credentials).to receive(:access_token).and_return("abc")
    expect(GaAuthorizer.token).to eq "abc"
  end

  it 'renews access token if expired' do
    allow(credentials).to receive(:expired?).and_return(true)
    allow(credentials).to receive(:access_token).and_return("abc")
    expect(credentials).to receive(:fetch_access_token!)
    GaAuthorizer.token
  end

  it 'fetches access token if one does not yet exist' do
    allow(credentials).to receive(:access_token).and_return(nil)
    expect(credentials).to receive(:fetch_access_token!)
    GaAuthorizer.token
  end
end