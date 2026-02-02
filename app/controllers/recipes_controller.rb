# frozen_string_literal: true

class RecipesController < ApplicationController
  def index
    @recipes = if params[:ingredients].present?
      search_recipes
    else
      featured_recipes
    end

    render inertia: "Recipes/Index", props: {
      recipes: serialize_recipes(@recipes),
      user_ingredients: params[:ingredients] || []
    }
  end

  def show
    @recipe = Recipe.find(params[:id])

    render inertia: "Recipes/Show", props: {
      recipe: serialize_recipe(@recipe),
      user_ingredients: params[:from]&.split(",") || []
    }
  end

  private

  def search_recipes
    RecipeSearchService.new(params[:ingredients]).search
  end

  def featured_recipes
    Recipe.order(ratings: :desc, title: :asc).limit(20)
  end

  def serialize_recipes(recipes)
    recipes.map { |recipe| serialize_recipe(recipe) }
  end

  def serialize_recipe(recipe)
    {
      id: recipe.id,
      title: recipe.title,
      image: recipe.image,
      category: recipe.category,
      author: recipe.author,
      ratings: recipe.ratings&.to_f,
      prep_time: recipe.prep_time,
      cook_time: recipe.cook_time,
      ingredients: recipe.ingredients,
      match_count: recipe.try(:match_count),
      ingredient_count: recipe.try(:ingredient_count)
    }
  end
end
