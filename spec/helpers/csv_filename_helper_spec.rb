require 'rails_helper'

describe CsvFilenameHelper, type: :helper do

  describe '#csv_filename' do
    it 'joins the parts with underscores' do
      expect(helper.csv_filename("HathiTrust", "Exhibition views", "2025-07_2026-07"))
        .to eq "HathiTrust_Exhibition-views_2025-07_2026-07.csv"
    end

    it 'drops blank parts, so hub-level downloads share the call' do
      expect(helper.csv_filename("HathiTrust", nil, "Exhibition views", nil))
        .to eq "HathiTrust_Exhibition-views.csv"
    end

    it 'makes hub names with slashes and commas safe' do
      expect(helper.csv_filename("NJ/DE Digital Collective", "University of Michigan, Ann Arbor"))
        .to eq "NJ-DE-Digital-Collective_University-of-Michigan-Ann-Arbor.csv"
    end
  end

  describe '#csv_date_range' do
    it 'gives both months for a range' do
      expect(helper.csv_date_range(Date.new(2025, 7, 1), Date.new(2026, 7, 31)))
        .to eq "2025-07_2026-07"
    end

    it 'gives one month when the range covers a single month' do
      expect(helper.csv_date_range(Date.new(2026, 7, 1), Date.new(2026, 7, 31)))
        .to eq "2026-07"
    end

    it 'is nil without dates' do
      expect(helper.csv_date_range(nil, nil)).to be_nil
    end
  end
end
