# frozen_string_literal: true

class RecipeSearchService
  attr_reader :keywords

  def initialize(user_input)
    @keywords = parse_input(user_input)
  end

  def search(limit: 50)
    return Recipe.none if keywords.empty?

    Recipe
      .where(ingredients_contain_keywords)
      .select(select_with_match_score)
      .order(order_by_relevance)
      .limit(limit)
  end

  private

  def parse_input(user_input)
    Array(user_input).join(" ")
                     .downcase
                     .gsub(/[^\w\s-]/, " ") # punctuation
                     .split(/\s+/)
                     .reject(&:blank?)
                     .reject { |k| k.length < 2 } # single char
                     .reject { |k| k.match?(/\A\d+\z/) } # numbers
                     .uniq
  end

  def ingredients_contain_keywords
    sanitized_keywords = keywords.map { |k| sanitize_for_tsquery(k) }
    query = sanitized_keywords.join(" | ")

    "ingredients_search_vector @@ to_tsquery('english', #{ActiveRecord::Base.connection.quote(query)})"
  end

  def select_with_match_score
    count_sql = match_count_sql
    <<~SQL.squish
      recipes.*,
      (#{count_sql})::integer AS match_count,
      array_length(ingredients, 1) AS ingredient_count,
      (#{count_sql})::float / NULLIF(array_length(ingredients, 1), 0) * 100 AS match_score,
      (#{count_sql})::float / NULLIF(#{keywords.size}, 0) * 100 AS coverage_score
    SQL
  end

  def match_count_sql
    clauses = keywords.map do |k|
      "ingredient ILIKE #{ActiveRecord::Base.connection.quote("%#{sanitize_like(k)}%")}"
    end.join(" OR ")

    "(SELECT COUNT(*) FROM unnest(recipes.ingredients) AS ingredient WHERE #{clauses})"
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
