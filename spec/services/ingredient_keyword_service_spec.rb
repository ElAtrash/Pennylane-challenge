# frozen_string_literal: true

RSpec.describe IngredientKeywordService do
  describe '.normalize_for_autocomplete' do
    it 'returns nil for nil input' do
      expect(described_class.normalize_for_autocomplete(nil)).to be_nil
    end

    it 'returns nil for blank input' do
      expect(described_class.normalize_for_autocomplete("")).to be_nil
      expect(described_class.normalize_for_autocomplete("   ")).to be_nil
    end

    it 'removes numbers and stop words' do
      result = described_class.normalize_for_autocomplete("2 cups all purpose flour")
      expect(result).to eq("all purpose flour")
    end

    it 'removes punctuation (commas, parentheses, slashes)' do
      result = described_class.normalize_for_autocomplete("1/2 cup sugar (granulated)")
      expect(result).to eq("sugar granulated")
    end

    it 'converts to lowercase' do
      result = described_class.normalize_for_autocomplete("CHICKEN Breast")
      expect(result).to eq("chicken breast")
    end

    it 'handles ingredients with spaces' do
      result = described_class.normalize_for_autocomplete("bell pepper")
      expect(result).to eq("bell pepper")
    end

    it 'filters words shorter than 2 characters' do
      result = described_class.normalize_for_autocomplete("a big tomato")
      expect(result).to eq("big tomato")
    end

    it 'preserves multi-word ingredients' do
      result = described_class.normalize_for_autocomplete("extra virgin olive oil")
      expect(result).to eq("extra virgin olive oil")
    end

    it 'returns nil when all words are filtered out' do
      result = described_class.normalize_for_autocomplete("1 2 3 cup of a")
      expect(result).to be_nil
    end
  end

  describe '.extract_all' do
    before do
      # Clear any existing recipes
      Recipe.destroy_all
    end

    it 'extracts unique normalized ingredients from all recipes', :aggregate_failures do
      Recipe.create!(
        title: "Recipe 1",
        ingredients: [ "2 cups flour", "1 cup sugar", "3 eggs" ]
      )
      Recipe.create!(
        title: "Recipe 2",
        ingredients: [ "1 cup flour", "butter", "vanilla extract" ]
      )

      result = described_class.extract_all

      expect(result).to include("flour", "sugar", "eggs", "butter", "vanilla extract")
      expect(result).to be_a(Array)
      expect(result.uniq.length).to eq(result.length)
    end

    it 'limits to 2-word ingredients maximum' do
      Recipe.create!(
        title: "Recipe",
        ingredients: [ "extra virgin olive oil", "bell pepper", "salt" ]
      )

      result = described_class.extract_all

      expect(result).to include("bell pepper")
      expect(result).not_to include("extra virgin olive oil")
    end

    it 'returns sorted results' do
      Recipe.create!(
        title: "Recipe",
        ingredients: [ "zucchini", "apple", "banana" ]
      )

      result = described_class.extract_all

      expect(result).to eq(result.sort)
    end

    it 'handles empty recipe database' do
      result = described_class.extract_all
      expect(result).to eq([])
    end

    it 'removes duplicate ingredients across recipes' do
      Recipe.create!(
        title: "Recipe 1",
        ingredients: [ "chicken", "salt" ]
      )
      Recipe.create!(
        title: "Recipe 2",
        ingredients: [ "chicken", "pepper" ]
      )

      result = described_class.extract_all

      expect(result.count("chicken")).to eq(1)
    end
  end

  describe '.all_keywords' do
    it 'returns cached ingredients' do
      cached_data = [ "apple", "banana", "carrot" ]
      allow(Rails.cache).to receive(:fetch).with("ingredient_keywords", expires_in: 1.day).and_return(cached_data)

      result = described_class.all_keywords

      expect(result).to eq(cached_data)
    end

    it 'uses Rails cache with correct key and expiration' do
      expect(Rails.cache).to receive(:fetch).with("ingredient_keywords", expires_in: 1.day)

      described_class.all_keywords
    end

    it 'calls extract_all when cache is empty' do
      allow(Rails.cache).to receive(:fetch).and_call_original
      expect(described_class).to receive(:extract_all).and_return([ "apple", "banana" ])

      described_class.all_keywords
    end
  end

  describe '.refresh_cache!' do
    before do
      Recipe.destroy_all
      Recipe.create!(
        title: "Test Recipe",
        ingredients: [ "chicken", "salt", "pepper" ]
      )
    end

    it 'refreshes the cache with current data' do
      expect(Rails.cache).to receive(:write).with("ingredient_keywords", anything, expires_in: 1.day)

      described_class.refresh_cache!
    end

    it 'writes to cache with correct key and expiration' do
      keywords = described_class.extract_all

      expect(Rails.cache).to receive(:write).with("ingredient_keywords", keywords, expires_in: 1.day)

      described_class.refresh_cache!
    end

    it 'returns the ingredient list' do
      result = described_class.refresh_cache!

      expect(result).to be_a(Array)
      expect(result).to include("chicken", "salt", "pepper")
    end
  end

  describe '.search' do
    before do
      allow(described_class).to receive(:all_keywords).and_return(
        [ "apple", "apricot", "banana", "beef", "bell pepper", "butter", "chicken" ]
      )
    end

    it 'returns keywords matching the prefix' do
      result = described_class.search("ap")
      expect(result).to eq([ "apple", "apricot" ])
    end

    it 'returns empty array for queries shorter than 2 characters', :aggregate_failures do
      expect(described_class.search("a")).to eq([])
      expect(described_class.search("")).to eq([])
      expect(described_class.search(nil)).to eq([])
    end

    it 'respects the limit parameter' do
      result = described_class.search("be", limit: 2)
      expect(result).to eq([ "beef", "bell pepper" ])
    end

    it 'is case insensitive' do
      result = described_class.search("AP")
      expect(result).to eq([ "apple", "apricot" ])
    end

    it 'matches words that start with the query in multi-word ingredients' do
      result = described_class.search("pe")
      expect(result).to include("bell pepper")
    end
  end
end
