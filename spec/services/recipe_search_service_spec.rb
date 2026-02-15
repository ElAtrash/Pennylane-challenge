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
      results = described_class.new([ "flour", "eggs", "milk" ]).search
      expect(results.first).to eq(pancakes)
      expect(results.first.match_score.round).to eq(100)
    end

    it "ranks higher match percentage before lower" do
      results = described_class.new([ "flour", "sugar" ]).search
      expect(results.first).to eq(simple_flour)
    end

    it "returns match_count and ingredient_count attributes" do
      results = described_class.new([ "flour", "sugar" ]).search
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

    it "treats space-separated string as a single ingredient requiring all words in tsquery" do
      results = described_class.new("flour eggs").search
      expect(results).not_to be_empty
      expect(results.first.match_count).to eq(0)
    end

    it "accepts array input for OR between ingredients" do
      results = described_class.new([ "flour", "eggs" ]).search
      expect(results).to include(pancakes, cookies)
    end

    it "requires all words in a phrase to match the same ingredient line" do
      results = described_class.new("cups flour").search
      expect(results).to include(pancakes, cookies)
      expect(results).not_to include(simple_flour)
    end

    context "with multi-word ingredient phrases" do
      let!(:whole_milk_recipe) do
        Recipe.create!(
          title: "Whole Milk Pancakes",
          ingredients: [ "1 cup whole milk", "2 eggs", "flour" ],
          ratings: 4.0
        )
      end

      let!(:whole_wheat_recipe) do
        Recipe.create!(
          title: "Whole Wheat Bread",
          ingredients: [ "whole wheat flour", "water", "yeast" ],
          ratings: 4.2
        )
      end

      it "matches 'whole milk' only to recipes with both words in same ingredient" do
        results = described_class.new("whole milk").search
        expect(results).to include(whole_milk_recipe)
        expect(results).not_to include(whole_wheat_recipe)
      end

      it "normalizes hyphens in search query to spaces" do
        results = described_class.new("whole-milk").search
        expect(results).to include(whole_milk_recipe)
        expect(results).not_to include(whole_wheat_recipe)
      end

      it "supports OR between phrase groups with array input" do
        results = described_class.new([ "whole milk", "eggs" ]).search
        expect(results).to include(whole_milk_recipe, pancakes, cookies)
        expect(results).not_to include(whole_wheat_recipe)
      end

      it "calculates coverage_score based on phrase groups matched" do
        results = described_class.new([ "whole milk", "eggs" ]).search
        recipe = results.find { |r| r.id == whole_milk_recipe.id }
        expect(recipe.coverage_score).to eq(100.0)
      end
    end
  end

  describe "#matched_ingredients" do
    let!(:recipe) do
      Recipe.create!(
        title: "Test Recipe",
        ingredients: [ "1 cup whole milk", "2 eggs", "1 cup flour" ],
        ratings: 4.0
      )
    end

    it "returns ingredients matching the search keywords" do
      service = described_class.new("milk")
      expect(service.matched_ingredients(recipe)).to eq([ "1 cup whole milk" ])
    end

    it "returns ingredients matching the search keywords singular form" do
      service = described_class.new("milks")
      expect(service.matched_ingredients(recipe)).to eq([ "1 cup whole milk" ])
    end

    it "returns multiple matched ingredients" do
      service = described_class.new(%w[milk eggs])
      expect(service.matched_ingredients(recipe)).to contain_exactly("1 cup whole milk", "2 eggs")
    end

    it "returns empty array when no keywords" do
      service = described_class.new("")
      expect(service.matched_ingredients(recipe)).to eq([])
    end

    it "requires all words in phrase to match same ingredient" do
      service = described_class.new("whole milk")
      expect(service.matched_ingredients(recipe)).to eq([ "1 cup whole milk" ])
    end

    it "normalizes hyphens in search and matches correctly" do
      service = described_class.new("whole-milk")
      expect(service.matched_ingredients(recipe)).to eq([ "1 cup whole milk" ])
    end

    it "is case insensitive" do
      service = described_class.new("MILK")
      expect(service.matched_ingredients(recipe)).to eq([ "1 cup whole milk" ])
    end
  end

  describe "#any_keywords?" do
    it "returns true when keywords present" do
      expect(described_class.new("flour").any_keywords?).to be true
    end

    it "returns false when input is empty" do
      expect(described_class.new("").any_keywords?).to be false
    end

    it "returns false when input contains only filtered terms" do
      expect(described_class.new([ "1", "a" ]).any_keywords?).to be false
    end
  end
end
