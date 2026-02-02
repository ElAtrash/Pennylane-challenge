# frozen_string_literal: true

RSpec.describe RecipeImporter do
  let(:file_path) { 'tmp/recipes.json' }
  let(:sample_data) do
    [
      {
        "title": "Golden Sweet Cornbread",
        "cook_time": 25,
        "prep_time": 10,
        "ingredients": [ "1 cup milk", "1 egg   " ],
        "ratings": 4.74,
        "category": "Cornbread",
        "author": "bluegirl",
        "image": "http://example.com/image.jpg"
      },
      {
        "title": "",
        "ingredients": [ "nothing" ]
      },
      {
        "title": "   ",
        "ingredients": [ "whitespace only" ]
      }
    ]
  end

  before do
    allow(File).to receive(:read).with(file_path).and_return(sample_data.to_json)
    allow($stdout).to receive(:write)
  end

  describe '#import!' do
    it 'creates recipe records with normalized data', :aggregate_failures do
      expect { described_class.new(file_path).import! }.to change(Recipe, :count).by(1)

      recipe = Recipe.find_by(title: "Golden Sweet Cornbread")
      expect(recipe.ratings).to eq(4.74)
      expect(recipe.category).to eq("Cornbread")
      expect(recipe.ingredients).to eq([ "1 cup milk", "1 egg" ])
      expect(recipe.cook_time).to eq(25)
      expect(recipe.prep_time).to eq(10)
    end

    it 'skips records missing a title' do
      described_class.new(file_path).import!
      expect(Recipe.where(ingredients: [ "nothing" ])).not_to exist
    end

    it 'skips records with blank or whitespace-only titles' do
      described_class.new(file_path).import!
      expect(Recipe.count).to eq(1)
      expect(Recipe.where(ingredients: [ "whitespace only" ])).not_to exist
    end

    it 'normalizes ingredients by stripping whitespace' do
      described_class.new(file_path).import!
      recipe = Recipe.find_by(title: "Golden Sweet Cornbread")
      expect(recipe.ingredients).to eq([ "1 cup milk", "1 egg" ])
    end

    it 'wraps the import in a transaction, rolling back on error' do
      allow(Recipe).to receive(:insert_all).and_raise(StandardError, "DB Error")

      expect {
        described_class.new(file_path).import!
      }.to raise_error(StandardError, "DB Error")

      expect(Recipe.count).to eq(0)
    end
  end
end
