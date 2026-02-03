import { Head, Link, router } from '@inertiajs/react'
import { useState } from 'react'
import IngredientInput from '../../components/IngredientInput'
import { RecipeIndexProps } from '../../types/recipe'

export default function Index({ recipes }: RecipeIndexProps) {
  const isSearchMode = recipes.some(r => r.matched_ingredients.length > 0)
  const [ingredients, setIngredients] = useState<string[]>([])

  const handleSearch = () => {
    if (ingredients.length === 0) {
      router.get('/', {}, { preserveState: true })
    } else {
      router.get('/', { ingredients }, { preserveState: true })
    }
  }

  const handleClearAndSearch = () => {
    setIngredients([])
    router.get('/', {}, { preserveState: true })
  }

  return (
    <>
      <Head title="Recipe Finder - Find recipes by ingredients" />
      
      <div className="bg-amber-50 mx-auto p-4">
        <div className="max-w-2xl mx-auto">
          <h1 className="text-3xl font-bold mb-6">Recipe Finder</h1>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              What ingredients do you have?
            </label>
            <IngredientInput
              ingredients={ingredients}
              onChange={setIngredients}
            />
          </div>

          <div className="flex gap-2 mb-8">
            <button
              onClick={handleSearch}
              disabled={ingredients.length === 0}
              className="px-6 py-2 bg-amber-500 text-white rounded-lg hover:bg-amber-600 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              Search Recipes
            </button>
            {isSearchMode && (
              <button
                onClick={handleClearAndSearch}
                className="px-4 py-2 text-gray-600 hover:text-gray-800 transition-colors"
              >
                Show all recipes
              </button>
            )}
          </div>
        </div>

        <div className="pt-6">
          <p className="text-gray-600 mb-4">
            {recipes.length} recipe{recipes.length !== 1 ? 's' : ''} found
            {isSearchMode && <span> matching your ingredients</span>}
          </p>

          {recipes.length === 0 ? (
            <p className="text-gray-500 text-center py-8">
              No recipes found. Try adding different ingredients.
            </p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {recipes.map((recipe) => {
                const displayLimit = 3
                const displayedMatches = recipe.matched_ingredients.slice(0, displayLimit)
                const remainingCount = recipe.matched_ingredients.length - displayLimit

                const totalTime = (recipe.prep_time || 0) + (recipe.cook_time || 0)
                const hasTime = recipe.prep_time !== null || recipe.cook_time !== null
                const hasRating = recipe.ratings !== null
                const showMetaRow = hasRating || hasTime

                return (
                  <Link
                    key={recipe.id}
                    href={`/recipes/${recipe.id}`}
                    className="block p-4 border rounded-xl hover:shadow-md transition-shadow bg-white"
                  >
                    <h3 className="font-semibold">{recipe.title}</h3>
                    {showMetaRow && (
                      <p className="text-sm text-gray-500">
                        {hasRating && <span>⭐ {recipe.ratings!.toFixed(1)}</span>}
                        {hasRating && hasTime && <span> · </span>}
                        {hasTime && <span>{totalTime} min</span>}
                      </p>
                    )}
                    {recipe.category && (
                      <p className="text-sm text-gray-400">{recipe.category}</p>
                    )}
                    {recipe.matched_ingredients.length > 0 && (
                      <div className="mt-3 pt-3 border-t border-gray-100">
                        <div className="flex flex-wrap gap-1 mb-1">
                          {displayedMatches.map((ingredient, idx) => (
                            <span
                              key={idx}
                              className="px-2 py-0.5 bg-green-100 text-green-700 text-xs rounded-full"
                            >
                              {ingredient}
                            </span>
                          ))}
                          {remainingCount > 0 && (
                            <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded-full">
                              +{remainingCount} more
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-gray-500">
                          You have {recipe.match_count}/{recipe.ingredient_count} ingredients
                        </p>
                      </div>
                    )}
                  </Link>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </>
  )
}
