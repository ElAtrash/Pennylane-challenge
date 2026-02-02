# frozen_string_literal: true

class RecipeImporter
  BATCH_SIZE = 1000

  def initialize(file_path)
    @file_path = file_path
  end

  def import!
    ActiveRecord::Base.transaction do
      parse_and_import
    end
    refresh_ingredient_keywords
  rescue StandardError => e
    puts "\n Import failed: #{e.message}"
    raise
  end

  private

  def parse_and_import
    data = JSON.parse(File.read(@file_path))
    total = data.size
    imported = 0

    data.each_slice(BATCH_SIZE) do |batch|
      records = batch.filter_map { |recipe_data| build_record(recipe_data) }

      Recipe.insert_all(records) if records.any?
      imported += records.size
      print "\r Imported: #{imported}/#{total} recipes."
    end
  end

  def build_record(data)
    return nil if data["title"].blank?

    {
      title: data["title"],
      cook_time: data["cook_time"],
      prep_time: data["prep_time"],
      ratings: data["ratings"],
      category: data["category"],
      author: data["author"],
      image: data["image"],
      ingredients: normalize_ingredients(data["ingredients"]),
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def refresh_ingredient_keywords
    keywords = IngredientKeywordService.refresh_cache!
    puts "\n Extracted #{keywords.size} unique keywords"
  end

  def normalize_ingredients(ingredients)
    return [] unless ingredients.is_a?(Array)

    ingredients.map { |ing| ing.strip.downcase }
  end
end
