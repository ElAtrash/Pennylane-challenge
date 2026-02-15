# frozen_string_literal: true

class RecipeSearchService
  attr_reader :keyword_groups

  def initialize(user_input)
    @keyword_groups = parse_input(user_input)
  end

  def keywords
    keyword_groups.flatten.uniq
  end

  def any_keywords?
    keyword_groups.any?
  end

  def search
    return Recipe.none if keyword_groups.empty?

    Recipe
      .where(ingredients_contain_keywords)
      .select(select_with_match_score)
      .order(order_by_relevance)
  end

  def matched_ingredients(recipe)
    return [] if keyword_groups.empty?

    recipe.ingredients.select do |ingredient|
      ingredient_lower = ingredient.downcase
      keyword_groups.any? do |words|
        words.all? do |word|
          ingredient_lower.include?(word) || ingredient_lower.include?(word.singularize)
        end
      end
    end
  end

  private

  def parse_input(user_input)
    Array(user_input).map do |ingredient|
      words = ingredient.to_s
                        .downcase
                        .gsub(/-/, " ")
                        .gsub(/[^\w\s]/, " ") # punctuation
                        .split(/\s+/)
                        .reject(&:blank?)
                        .reject { |k| k.length < 2 } # single char
                        .reject { |k| k.match?(/\A\d+\z/) } # numbers
                        .uniq
      words.empty? ? nil : words
    end.compact
  end

  def ingredients_contain_keywords
    return "1=0" if keyword_groups.empty?

    phrase_queries = keyword_groups.map do |words|
      sanitized = words.map { |w| sanitize_for_tsquery(w) }
      "(#{sanitized.join(' & ')})"
    end

    query = phrase_queries.join(" | ")
    "ingredients_search_vector @@ to_tsquery('english', #{ActiveRecord::Base.connection.quote(query)})"
  end

  def select_with_match_score
    count_sql = match_count_sql
    <<~SQL.squish
      recipes.*,
      (#{count_sql})::integer AS match_count,
      array_length(ingredients, 1) AS ingredient_count,
      (#{count_sql})::float / NULLIF(array_length(ingredients, 1), 0) * 100 AS match_score,
      (#{count_sql})::float / NULLIF(#{keyword_groups.size}, 0) * 100 AS coverage_score
    SQL
  end

  # Counts how many input ingredients match a recipe ingredient line
  def match_count_sql
    phrase_checks = keyword_groups.map do |words|
      conditions = words.map do |w|
        "ingredient ILIKE #{ActiveRecord::Base.connection.quote("%#{sanitize_like(w)}%")}"
      end.join(" AND ")
      "(#{conditions})"
    end

    "(SELECT COUNT(*) FROM unnest(recipes.ingredients) AS ingredient WHERE #{phrase_checks.join(' OR ')})"
  end

  def order_by_relevance
    Arel.sql(<<~SQL.squish
      match_score DESC,
      coverage_score DESC,
      array_length(ingredients, 1) ASC,
      ratings DESC NULLS LAST
    SQL
    )
  end

  def sanitize_for_tsquery(keyword)
    keyword.gsub(/[^\w-]/, "")
  end

  def sanitize_like(string)
    ActiveRecord::Base.sanitize_sql_like(string)
  end
end
