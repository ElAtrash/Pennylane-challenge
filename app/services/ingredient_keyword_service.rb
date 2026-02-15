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
          .map { |ingredient| normalize_for_autocomplete(ingredient) }
          .compact
          .select { |ingredient| ingredient.split(/\s+/).length <= 2 }
          .uniq
          .sort
  end

  def self.normalize_for_autocomplete(ingredient_string)
    return nil if ingredient_string.nil? || ingredient_string.blank?

    words = ingredient_string
              .downcase
              .gsub(/[^\w\s]/, " ")
              .split(/\s+/)
              .reject(&:blank?)
              .reject { |word| STOP_WORDS.include?(word) }
              .reject { |word| word.match?(/\A\d+\z/) }  # Remove numbers
              .reject { |word| word.length < 2 }

    result = words.join(" ").strip
    result.present? ? result : nil
  end

  # Search keywords with prefix matching
  def self.search(query, limit: 8)
    return [] if query.to_s.length < 2

    all_keywords.select do |ingredient|
      ingredient.split(/\s+/).any? { |word| word.start_with?(query.downcase.strip) }
    end.take(limit)
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
