# frozen_string_literal: true

RSpec.describe "Recipes", type: :request do
  before { Recipe.delete_all }

  let!(:high_rated_recipe) do
    Recipe.create!(
      title: "Best Pancakes",
      ingredients: [ "2 cups flour", "2 eggs", "1 cup milk" ],
      ratings: 4.9
    )
  end

  let!(:low_rated_recipe) do
    Recipe.create!(
      title: "Simple Toast",
      ingredients: [ "bread", "butter" ],
      ratings: 3.5
    )
  end

  let!(:medium_rated_recipe) do
    Recipe.create!(
      title: "Cookies",
      ingredients: [ "flour", "sugar", "eggs" ],
      ratings: 4.2
    )
  end

  describe "GET /" do
    context "without ingredients" do
      it "returns featured recipes ordered by ratings desc", :aggregate_failures do
        get "/"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Best Pancakes")
        expect(response.body).to include("Simple Toast")
        expect(response.body).to include("Cookies")
      end
    end

    context "with ingredients" do
      it "filters recipes by matching ingredients", :aggregate_failures do
        get "/", params: { ingredients: [ "flour" ] }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Best Pancakes")
        expect(response.body).to include("Cookies")
        expect(response.body).not_to include("Simple Toast")
      end

      it "returns recipes matching multiple ingredients", :aggregate_failures do
        get "/", params: { ingredients: [ "flour", "eggs" ] }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Best Pancakes")
        expect(response.body).to include("Cookies")
      end
    end

    context "with pagination" do
      before do
        25.times do |i|
          Recipe.create!(
            title: "Recipe #{i}",
            ingredients: [ "ingredient #{i}" ],
            ratings: 4.0
          )
        end
      end

      it "returns paginated results" do
        get "/", params: { page: 1 }

        expect(response).to have_http_status(:ok)
      end

      it "returns second page of results" do
        get "/", params: { page: 2 }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /recipes/:id" do
    it "shows recipe detail" do
      get "/recipes/#{high_rated_recipe.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Best Pancakes")
    end

    it "preserves search ingredients in context" do
      get "/recipes/#{high_rated_recipe.id}", params: { ingredients: [ "flour", "eggs" ] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Best Pancakes")
    end

    it "returns 404 for non-existent recipe" do
      get "/recipes/999999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
