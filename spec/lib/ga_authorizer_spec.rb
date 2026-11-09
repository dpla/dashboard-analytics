require 'rails_helper'

describe GaAuthorizer do

  after do
    if GaAuthorizer.class_variable_defined? :@@credentials
      GaAuthorizer.remove_class_variable :@@credentials
    end
  end

  it 'builds read-only credentials once' do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read)
      .with(Settings.google_analytics.service_account_json_key).and_return("{}")
    expect(Google::Auth::ServiceAccountCredentials).to receive(:make_creds)
      .once
      .with(hash_including(scope: 'https://www.googleapis.com/auth/analytics.readonly'))
      .and_return(double)

    2.times { GaAuthorizer.credentials }
  end
end
