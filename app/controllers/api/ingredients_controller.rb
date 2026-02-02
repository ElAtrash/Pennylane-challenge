# frozen_string_literal: true

module Api
  class IngredientsController < ApplicationController
    def index
      ingredients = IngredientKeywordService.search(params[:q])
      render json: { ingredients: ingredients }
    end
  end
end
