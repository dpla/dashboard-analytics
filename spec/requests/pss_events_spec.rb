require 'rails_helper'

RSpec.describe "Primary source set views", type: :request do
  let(:admin) do
    User.create(email: "admin@example.com", password: "password",
                password_confirmation: "password", admin: true, hub: "All")
  end

  let(:sources) do
    {
      "the-new-deal/12" => { "item" => "abc123", "hub" => "HathiTrust",
                             "contributor" => "University of Michigan",
                             "title" => "A Poster" },
      "the-new-deal/13" => { "item" => "def456", "hub" => "Digital Commonwealth",
                             "contributor" => "Boston Public Library",
                             "title" => "A Map" }
    }
  end

  let(:page_views) do
    cached_response(%w(pagePath screenPageViews),
                    [["/primary-source-sets/the-new-deal/sources/12", "150"],
                     ["/primary-source-sets/the-new-deal/sources/13", "900"]])
  end

  before(:each) do
    sign_in admin
    stub_ga_cache_passthrough
    allow(WebsiteActivityMonths).to receive(:build)
      .and_return(instance_double(WebsiteActivityMonths, earliest_month: nil))
    allow(PssSources).to receive(:sources).and_return(sources)
    allow(GaResponseBuilder).to receive(:build)
      .and_return(double(multi_page_response: [page_views]))
    allow_any_instance_of(DplaApiResponseBuilder)
      .to receive(:curated_memberships).and_return("abc123" => ["the-new-deal"])
  end

  it "shows the hub's source views, attributed through the source map" do
    get "/website_events", params: { hub_id: "HathiTrust", event_id: "view_pss" }
    expect(response.body).to include("A Poster", "University of Michigan", "150")
    expect(response.body).to match(/of\s+1 items/)
  end

  it "links the source sets an item belongs to" do
    get "/website_events", params: { hub_id: "HathiTrust", event_id: "view_pss" }
    expect(response.body)
      .to include("https://dp.la/primary-source-sets/the-new-deal")
  end

  it "exports every row as CSV" do
    get "/website_events", params: { hub_id: "HathiTrust", event_id: "view_pss",
                                     format: :csv }
    expect(response.body).to include("abc123", "University of Michigan", "150")
  end

  it "offers the date menu back to the start of page view data" do
    get "/hubs/HathiTrust/events/view_pss"
    expect(response.body).to include("2023")
  end

  it "keeps the later floor for event-backed tables" do
    allow(WebsiteEvents).to receive(:build)
      .and_return(double(response: nil, event_name: "View Item",
                         multi_page_response: []))
    get "/hubs/HathiTrust/events/view_item"
    expect(response.body).not_to include("2023")
  end
end
