# frozen_string_literal: true

namespace :recipes do
  desc "Import recipes from JSON file"
  task :import, [ :file_path ] => :environment do |t, args|
    file_path = args[:file_path] || Rails.root.join("data", "recipes.json")

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit 1
    end

    RecipeImporter.new(file_path).import!
  end

  desc "Clear all recipes"
  task clear: :environment do
    Recipe.delete_all
    puts "All recipes deleted"
  end

  desc "Extract ingredient keywords for autocomplete (also runs automatically after import)"
  task extract_keywords: :environment do
    keywords = IngredientKeywordService.refresh_cache!
    puts "Extracted #{keywords.size} unique keywords"
  end
end
