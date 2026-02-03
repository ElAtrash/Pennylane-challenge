export interface Recipe {
  id: number;
  title: string;
  category: string | null;
  author: string | null;
  ratings: number | null;
  prep_time: number | null;
  cook_time: number | null;
  ingredients: string[];
  matched_ingredients: string[];
  match_count?: number;
  ingredient_count?: number;
}

export interface RecipeIndexProps {
  recipes: Recipe[];
}

export interface RecipeShowProps {
  recipe: Recipe;
}
