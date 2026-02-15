import { Head, Link, router } from '@inertiajs/react'
import { useEffect, useState } from 'react'
import IngredientInput from '../../components/IngredientInput'
import { RecipeIndexProps } from '../../types/recipe'

export default function Index({ recipes, pagination, search_ingredients = [] }: RecipeIndexProps) {
  const isSearchMode = recipes.some(r => r.matched_ingredients.length > 0)
  const [ingredients, setIngredients] = useState<string[]>(search_ingredients)

  // Insta search with debounce
  useEffect(() => {
    if (JSON.stringify(ingredients) === JSON.stringify(search_ingredients)) return

    const timer = setTimeout(() => {
      router.get('/',
        ingredients.length > 0 ? { ingredients } : {},
        {
          preserveState: true,
          replace: true,
          only: ['recipes', 'pagination', 'search_ingredients']
        }
      )
    }, 300)

    return () => clearTimeout(timer)
  }, [ingredients])

  const goToPage = (page: number) => {
    const url = new URL(window.location.href)
    url.searchParams.set('page', String(page))
    router.get(url.pathname + url.search, {}, { preserveState: true })
  }

  const recipeUrl = (id: number) => {
    if (ingredients.length === 0) return `/recipes/${id}`
    const params = ingredients.map(i => `ingredients[]=${encodeURIComponent(i)}`).join('&')
    return `/recipes/${id}?${params}`
  }

  return (
    <>
      <Head title="OmNom - Find recipes by ingredients" />

      <div className="bg-amber-50 mx-auto p-4">
        <div className="max-w-2xl mx-auto">
          <h1 className="text-3xl font-bold mb-6">OmNom - Find recipes by ingredients</h1>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              What ingredients do you have?
            </label>
            <IngredientInput
              ingredients={ingredients}
              onChange={setIngredients}
            />
          </div>
        </div>

        <div className="pt-6">
          {isSearchMode && (
            <p className="text-gray-600 mb-4">
              {pagination.count} recipe{pagination.count !== 1 ? 's' : ''} found matching your ingredients
            </p>
          )}

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
                    href={recipeUrl(recipe.id)}
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

          {pagination.pages > 1 && (
            <div className="flex justify-center items-center gap-4 mt-8">
              <button
                onClick={() => goToPage(pagination.previous!)}
                disabled={!pagination.previous}
                className="px-4 py-2 text-amber-600 hover:text-amber-700 disabled:text-gray-300 disabled:cursor-not-allowed"
              >
                ← Previous
              </button>
              <span className="text-gray-600">
                Page {pagination.page} of {pagination.pages}
              </span>
              <button
                onClick={() => goToPage(pagination.next!)}
                disabled={!pagination.next}
                className="px-4 py-2 text-amber-600 hover:text-amber-700 disabled:text-gray-300 disabled:cursor-not-allowed"
              >
                Next →
              </button>
            </div>
          )}
        </div>
      </div>
    </>
  )
}
