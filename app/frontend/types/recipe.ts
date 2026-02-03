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

export interface Pagination {
  page: number;
  pages: number;
  count: number;
  next: number | null;
  previous: number | null;
}

export interface RecipeIndexProps {
  recipes: Recipe[];
  pagination: Pagination;
}

export interface RecipeShowProps {
  recipe: Recipe;
}
