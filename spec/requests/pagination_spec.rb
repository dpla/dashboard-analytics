require 'rails_helper'

RSpec.describe "Table pagination", type: :request do

  let(:admin) { User.create(email: "admin@example.com",
                            password: "password",
                            password_confirmation: "password",
                            admin: true,
                            hub: "All") }

  before(:each) { sign_in admin }

  # Builds a Ga4Response from a stubbed GA4 report.
  def ga4_page(rows:, total:, dimensions:, metrics:)
    inner_rows = rows.map do |dims, metric|
      double(dimension_values: Array(dims).map { |d| double(value: d) },
             metric_values: [double(value: metric)])
    end
    inner = double(rows: inner_rows, row_count: total)
    GaResponseBuilder::Ga4Response.new(inner, dimensions, metrics)
  end

  describe "contributor tables" do
    # 120 contributors with descending counts, so sorted order is 001..120.
    let(:contributors) do
      (1..120).each_with_object({}) do |i, hash|
        hash[format("Contributor %03d", i)] = 1000 - i
      end
    end

    before(:each) do
      allow(HubStats).to receive(:fetch).and_return(
        { "hubs" => { "foo" => { "item_count" => 999,
                                 "contributors" => contributors } } }
      )
      allow(HubStats).to receive(:fetch_bws).and_return({ "hubs" => {} })
      allow(MetadataCompleteness).to receive(:build).and_return(
        instance_double(MetadataCompleteness, contributor_csv: [])
      )
      allow(WebsiteOverviewByContributor).to receive(:build)
        .and_return(double(response: nil, parse_data: {}))
      allow(WebsiteEventsByContributor).to receive(:build)
        .and_return(double(response: nil, parse_data: {}))
    end

    describe "contributors index placeholder" do
      it "renders only the first page of contributors" do
        get "/hubs/foo/contributors"
        expect(response.body).to include("Contributor 001", "Contributor 050")
        expect(response.body).not_to include("Contributor 051")
      end

      it "passes the page through to the async comparison request" do
        get "/hubs/foo/contributors?page=2"
        expect(response.body).to match(/contributor_comparison\?[^"]*page=2/)
        expect(response.body).to include("Contributor 051", "Contributor 100")
        expect(response.body).not_to include("Contributor 101")
      end
    end

    describe "contributor comparison table" do
      it "renders the first page with a count and next link" do
        get "/contributor_comparison", params: { hub_id: "foo" }
        expect(response.body).to include("Showing 1-50")
        expect(response.body).to include("of 120 contributors")
        expect(response.body).to include("Contributor 050")
        expect(response.body).not_to include("Contributor 051")
        expect(response.body).to match(%r{/hubs/foo/contributors\?page=2})
      end

      it "renders the last page with a previous link and no next link" do
        get "/contributor_comparison", params: { hub_id: "foo", page: 3 }
        expect(response.body).to include("Showing 101-120")
        expect(response.body).to include("Contributor 101", "Contributor 120")
        expect(response.body).not_to include("Contributor 100</a>")
        expect(response.body).to match(%r{/hubs/foo/contributors\?page=2})
        expect(response.body).not_to include("Next")
      end

      it "exports all contributors to CSV regardless of page" do
        get "/contributor_comparison", params: { hub_id: "foo", page: 3,
                                                 format: "csv" }
        expect(response.body).to include("Contributor 001", "Contributor 120")
      end
    end

    describe "contributor GA data JSON" do
      it "returns data only for the requested page of contributors" do
        get "/contributor_ga_data", params: { hub_id: "foo", page: 3 }
        data = JSON.parse(response.body)
        expect(data.keys.length).to eq 20
        expect(data.keys.first).to eq "Contributor 101"
        expect(data.keys.last).to eq "Contributor 120"
      end

      it "defaults to the first page" do
        get "/contributor_ga_data", params: { hub_id: "foo" }
        data = JSON.parse(response.body)
        expect(data.keys.length).to eq 50
        expect(data.keys.first).to eq "Contributor 001"
      end
    end
  end

  describe "search terms table" do
    before(:each) do
      page = ga4_page(rows: [[["cats"], "12"], [["dogs"], "10"]],
                      total: 120,
                      dimensions: %w(ga:searchKeyword),
                      metrics: %w(ga:searchUniques))
      allow(WebsiteSearchTerms).to receive(:build)
        .and_return(double(response: page))
    end

    it "shows the page window and prev/next links" do
      get "/website_search_terms", params: { page: 2 }
      expect(response.body).to include("Showing 51-")
      expect(response.body).to include("of 120 search terms")
      expect(response.body).to include("cats", "dogs")
      expect(response.body).to include("/search_terms/website?page=1")
      expect(response.body).to include("/search_terms/website?page=3")
    end
  end

  describe "events table" do
    before(:each) do
      page = ga4_page(rows: [[["abc123 : Some Item", "Some Contributor"], "42"]],
                      total: 120,
                      dimensions: %w(ga:eventLabel ga:eventAction),
                      metrics: %w(ga:totalEvents))
      allow(WebsiteEvents).to receive(:build)
        .and_return(double(response: page, event_name: "View Item",
                           multi_page_response: []))
      allow_any_instance_of(DplaApiResponseBuilder)
        .to receive(:data_providers_for_items).and_return({})
    end

    it "shows the page window and prev/next links" do
      get "/website_events", params: { hub_id: "foo", event_id: "view_item",
                                       page: 2 }
      expect(response.body).to include("Showing 51-")
      expect(response.body).to match(/of\s+120 items/)
      expect(response.body).to include("Some Item")
      expect(response.body).to match(%r{/hubs/foo/events/view_item\?page=1})
      expect(response.body).to match(%r{/hubs/foo/events/view_item\?page=3})
    end

    it "builds contributor-scoped page links" do
      get "/website_events", params: { hub_id: "foo", contributor_id: "bar",
                                       event_id: "view_item", page: 2 }
      expect(response.body)
        .to match(%r{/hubs/foo/contributors/bar/events/view_item\?page=3})
    end
  end
end
