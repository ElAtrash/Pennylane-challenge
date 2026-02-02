# frozen_string_literal: true

RSpec.describe IngredientKeywordService do
  describe '.extract_from' do
    it 'removes numbers and stop words' do
      result = described_class.extract_from("2 cups all-purpose flour")
      expect(result).to eq([ "all-purpose", "flour" ])
    end

    it 'handles empty string' do
      result = described_class.extract_from("")
      expect(result).to eq([])
    end

    it 'handles special characters' do
      result = described_class.extract_from("1/2 cup sugar (granulated)")
      expect(result).to eq(%w[sugar granulated])
    end
  end

  describe '.search' do
    before do
      allow(described_class).to receive(:all_keywords).and_return(
        %w[apple apricot banana beef bell-pepper butter chicken]
      )
    end

    it 'returns keywords matching the prefix' do
      result = described_class.search("ap")
      expect(result).to eq(%w[apple apricot])
    end

    it 'returns empty array for queries shorter than 2 characters', :aggregate_failures do
      expect(described_class.search("a")).to eq([])
      expect(described_class.search("")).to eq([])
      expect(described_class.search(nil)).to eq([])
    end

    it 'respects the limit parameter' do
      result = described_class.search("be", limit: 2)
      expect(result).to eq(%w[beef bell-pepper])
    end

    it 'is case insensitive' do
      result = described_class.search("AP")
      expect(result).to eq(%w[apple apricot])
    end
  end
end
