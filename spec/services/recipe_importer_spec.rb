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
        "author": "bluegirl"
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

    it 'normalizes hyphens in ingredients to spaces' do
      allow(File).to receive(:read).with(file_path).and_return([
        { "title" => "Naan", "ingredients" => [ "1 cup whole-milk yogurt" ] }
      ].to_json)

      described_class.new(file_path).import!
      recipe = Recipe.find_by(title: "Naan")
      expect(recipe.ingredients).to eq([ "1 cup whole milk yogurt" ])
    end

    it 'wraps the import in a transaction, rolling back on error' do
      allow(Recipe).to receive(:insert_all).and_raise(StandardError, "DB Error")

      expect {
        described_class.new(file_path).import!
      }.to raise_error(StandardError, "DB Error")

      expect(Recipe.count).to eq(0)
    end
  end

  describe '#fix_image_url' do
    let(:importer) { described_class.new(file_path) }

    it 'returns nil for blank URLs' do
      expect(importer.send(:fix_image_url, nil)).to be_nil
      expect(importer.send(:fix_image_url, '')).to be_nil
      expect(importer.send(:fix_image_url, '   ')).to be_nil
    end

    it 'adds query parameters to Meredith Corp image URLs without existing params' do
      url = 'https://imagesvc.meredithcorp.io/v3/mm/image'
      result = importer.send(:fix_image_url, url)
      expect(result).to eq("#{url}?w=400&h=300&q=80&c=1")
    end

    it 'appends query parameters to Meredith Corp URLs with existing params' do
      url = 'https://imagesvc.meredithcorp.io/v3/mm/image?fit=crop'
      result = importer.send(:fix_image_url, url)
      expect(result).to eq("#{url}&w=400&h=300&q=80&c=1")
    end

    it 'returns other URLs unchanged' do
      url = 'https://example.com/image.jpg'
      expect(importer.send(:fix_image_url, url)).to eq(url)
    end
  end

  describe '#normalize_ingredients' do
    let(:importer) { described_class.new(file_path) }

    it 'returns empty array for nil input' do
      expect(importer.send(:normalize_ingredients, nil)).to eq([])
    end

    it 'returns empty array for non-array input' do
      expect(importer.send(:normalize_ingredients, 'not an array')).to eq([])
      expect(importer.send(:normalize_ingredients, 123)).to eq([])
    end

    it 'downcases ingredients' do
      result = importer.send(:normalize_ingredients, [ 'CHICKEN', 'Garlic' ])
      expect(result).to eq([ 'chicken', 'garlic' ])
    end

    it 'collapses multiple spaces to single space' do
      result = importer.send(:normalize_ingredients, [ 'chicken    breast' ])
      expect(result).to eq([ 'chicken breast' ])
    end

    it 'applies all normalizations together', :aggregate_failures do
      result = importer.send(:normalize_ingredients, [
        '  WHOLE-MILK   Yogurt  ',
        'Red-Pepper    Flakes'
      ])
      expect(result).to eq([
        'whole milk yogurt',
        'red pepper flakes'
      ])
    end
  end
end
