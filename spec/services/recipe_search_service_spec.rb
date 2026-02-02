# frozen_string_literal: true

RSpec.describe RecipeSearchService do
  before { Recipe.delete_all }

  let!(:pancakes) do
    Recipe.create!(
      title: "Pancakes",
      ingredients: [ "2 cups flour", "2 eggs", "1 cup milk" ],
      ratings: 4.5
    )
  end

  let!(:cookies) do
    Recipe.create!(
      title: "Cookies",
      ingredients: [ "2 cups flour", "1 cup sugar", "2 eggs" ],
      ratings: 4.8
    )
  end

  let!(:simple_flour) do
    Recipe.create!(
      title: "Simple Flour",
      ingredients: [ "flour" ],
      ratings: 5
    )
  end

  let!(:sugar_and_flour) do
    Recipe.create!(
      title: "Sugar and Flour",
      ingredients: [ "flour", "sugar", "eggs" ],
      ratings: 5
    )
  end

  describe "#search" do
    it "finds recipes with matching ingredients" do
      results = described_class.new("flour").search
      expect(results).to include(pancakes, cookies)
    end

    it "returns empty when no recipes match" do
      results = described_class.new("abcd").search
      expect(results).to be_empty
    end

    it "handles empty input" do
      results = described_class.new("").search
      expect(results).to be_empty
    end

    it "ranks recipes by match percentage" do
      results = described_class.new("flour eggs milk").search
      expect(results.first).to eq(pancakes)
      expect(results.first.match_score.round).to eq(100)
    end

    it "ranks higher match percentage before lower" do
      results = described_class.new([ "flour", "sugar" ]).search
      expect(results.first).to eq(simple_flour)
    end

    it "returns match_count and ingredient_count attributes" do
      results = described_class.new("flour sugar").search
      recipe = results.find { |r| r.id == sugar_and_flour.id }

      expect(recipe.match_count).to eq(2)
      expect(recipe.ingredient_count).to eq(3)
    end

    it "is case insensitive" do
      results = described_class.new("FLOUR").search
      expect(results).to include(pancakes)
    end

    it "filters out short keywords and numbers" do
      results = described_class.new([ "1", "c" ]).search
      expect(results).to be_empty
    end

    it "accepts string input with space separators" do
      results = described_class.new("flour eggs").search
      expect(results).to include(pancakes, cookies)
    end

    it "accepts string input with comma separators" do
      results = described_class.new("flour,eggs").search
      expect(results).to include(pancakes, cookies)
    end

    it "accepts array input" do
      results = described_class.new([ "flour", "eggs" ]).search
      expect(results).to include(pancakes, cookies)
    end
  end
end
