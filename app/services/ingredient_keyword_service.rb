# frozen_string_literal: true

class IngredientKeywordService
  STOP_WORDS = Set.new(%w[
    cup cups tablespoon tablespoons teaspoon teaspoons tsp tbsp
    pound pounds ounce ounces oz lb lbs
    chopped diced minced sliced
    fresh dried ground
    to taste optional
    and or of
  ]).freeze

  # Extract all unique keywords from all recipes
  def self.extract_all
    Recipe.pluck(:ingredients)
          .flatten
          .flat_map { |ingredient| extract_from(ingredient) }
          .uniq
          .sort
  end

  # Extract keywords from a single ingredient string
  def self.extract_from(ingredient_string)
    return [] if ingredient_string.nil?

    ingredient_string
      .downcase
      .gsub(/\d+/, "")          # Remove numbers
      .gsub(/[^\w\s-]/, "")     # Keep only words and dashes
      .split(/\s+/)
      .reject { |word| STOP_WORDS.include?(word) }
      .select { |word| word.length > 2 }
  end

  # Search keywords with prefix matching
  def self.search(query, limit: 8)
    return [] if query.to_s.length < 2

    all_keywords.select { |keyword| keyword.start_with?(query.downcase) }
                .take(limit)
  end

  def self.all_keywords
    Rails.cache.fetch("ingredient_keywords", expires_in: 1.day) do
      extract_all
    end
  end

  def self.refresh_cache!
    keywords = extract_all
    Rails.cache.write("ingredient_keywords", keywords, expires_in: 1.day)
    keywords
  end
end
