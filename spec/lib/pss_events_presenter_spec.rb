require 'rails_helper'

describe PssEventsPresenter do
  let(:columns) do
    %w[ga:eventLabel ga:eventAction ga:totalEvents]
      .map { |name| double(name: name) }
  end
  let(:row) { ['abc123 : A Poster', 'University of Michigan', '150'] }
  let(:ga_data) { double(column_headers: columns, rows: [row], total_results: 1) }
  let(:ga_response) do
    double(response: ga_data, multi_page_response: [ga_data],
           event_name: 'View Primary Source', hub: 'HathiTrust', contributor: nil,
           memberships: { 'abc123' => ['the-new-deal'] })
  end
  let(:presenter) { described_class.new(ga_response) }

  it 'takes the contributor from the row, without an S3 or API lookup' do
    expect(ItemDataProviders).not_to receive(:items)
    expect(DplaApiResponseBuilder).not_to receive(:new)
    expect(presenter.contributor(row)).to eq 'University of Michigan'
  end

  it 'labels the table as source set views' do
    expect(presenter.label).to eq 'Primary source set views'
  end

  it 'takes source set membership from the rows, not the DPLA API' do
    expect(DplaApiResponseBuilder).not_to receive(:new)
    expect(presenter.membership_kind).to eq :primary_source_sets
    expect(presenter.memberships(row)).to eq ['the-new-deal']
  end

  it 'exports a CSV with the source set column' do
    csv = CSV.parse(presenter.to_csv, headers: true)
    expect(csv.headers)
      .to eq ['Item', 'Item ID', 'Contributor', 'Primary source set views',
              'Primary source sets']
    expect(csv.first.fields)
      .to eq ['A Poster', 'abc123', 'University of Michigan', '150', 'the-new-deal']
  end
end
