# frozen_string_literal: true

class RecipesController < ApplicationController
  include Pagy::Method

  def index
    @pagy, @recipes = pagy(:offset, recipes, limit: 21)

    render inertia: "Recipes/Index", props: {
      recipes: serialize_recipes(@recipes),
      pagination: pagy_metadata
    }
  end

  def show
    render inertia: "Recipes/Show", props: {
      recipe: serialize_recipe(Recipe.find(params[:id]))
    }
  end

  private

  def recipes
    search_service.any_keywords? ? search_service.search : featured_recipes
  end

  def featured_recipes
    Recipe.order(ratings: :desc, title: :asc)
  end

  def search_service
    user_input = params[:ingredients] || params[:from]&.split(",") || []
    @search_service ||= RecipeSearchService.new(user_input)
  end

  def serialize_recipes(recipes)
    recipes.map { |recipe| serialize_recipe(recipe) }
  end

  def serialize_recipe(recipe)
    {
      id: recipe.id,
      title: recipe.title,
      category: recipe.category,
      author: recipe.author,
      ratings: recipe.ratings&.to_f,
      prep_time: recipe.prep_time,
      cook_time: recipe.cook_time,
      ingredients: recipe.ingredients,
      matched_ingredients: search_service.matched_ingredients(recipe),
      match_count: recipe.try(:match_count),
      ingredient_count: recipe.try(:ingredient_count)
    }
  end

  def pagy_metadata
    {
      page: @pagy.page,
      pages: @pagy.pages,
      count: @pagy.count,
      next: @pagy.next,
      previous: @pagy.previous
    }
  end
end
