import { Head, Link, router } from '@inertiajs/react'
import { useEffect, useState } from 'react'
import IngredientInput from '../../components/IngredientInput'
import { RecipeIndexProps } from '../../types/recipe'

const MATCHED_INGREDIENT_DISPLAY_LIMIT = 3

export default function Index({ recipes, pagination, search_ingredients = [] }: RecipeIndexProps) {
  const isSearchMode = recipes.some(r => r.matched_ingredients.length > 0)
  const [ingredients, setIngredients] = useState<string[]>(search_ingredients)

  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    e.currentTarget.style.display = 'none'
    const placeholder = e.currentTarget.nextElementSibling as HTMLElement
    placeholder?.classList.remove('hidden')
  }

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
            <div className="grid grid-cols-3 gap-4">
              {recipes.map((recipe) => (
                  <Link
                    key={recipe.id}
                    href={recipeUrl(recipe.id)}
                    className="block relative border border-gray-200 rounded-xl shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-200 bg-white overflow-hidden group"
                  >
                    {recipe.image ? (
                      <img
                        src={recipe.image}
                        alt={recipe.title}
                        className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-200"
                        onError={handleImageError}
                      />
                    ) : null}

                    {/* Placeholder */}
                    <div className={`w-full h-48 bg-linear-to-br from-amber-100 to-amber-200 flex items-center justify-center ${recipe.image ? 'hidden' : ''}`}>
                      <svg className="w-16 h-16 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                    </div>

                    {/* Match percentage badge */}
                    {recipe.matched_ingredients.length > 0 && recipe.match_count && recipe.ingredient_count && (
                      <div className="absolute top-3 right-3 bg-green-500 text-white px-3 py-1.5 rounded-full text-sm font-bold shadow-lg">
                        {Math.round((recipe.match_count / recipe.ingredient_count) * 100)}% match
                      </div>
                    )}

                    <div className="p-4">
                      <h3 className="text-lg font-bold text-gray-900 line-clamp-2 mb-2">{recipe.title}</h3>
                      {(recipe.ratings || recipe.prep_time || recipe.cook_time) && (
                        <p className="text-sm text-gray-500 flex items-center gap-2">
                          {recipe.ratings && (
                            <>
                              <span className="inline-flex items-center gap-1 text-amber-600 font-semibold">
                                <svg className="w-4 h-4 fill-current" viewBox="0 0 20 20">
                                  <path d="M10 15l-5.878 3.09 1.123-6.545L.489 6.91l6.572-.955L10 0l2.939 5.955 6.572.955-4.756 4.635 1.123 6.545z" />
                                </svg>
                                {recipe.ratings.toFixed(1)}
                              </span>
                              {(recipe.prep_time || recipe.cook_time) && <span>·</span>}
                            </>
                          )}
                          {(recipe.prep_time || recipe.cook_time) && (
                            <span>{(recipe.prep_time || 0) + (recipe.cook_time || 0)} min</span>
                          )}
                        </p>
                      )}
                      {recipe.category && (
                        <p className="text-sm text-gray-400">{recipe.category}</p>
                      )}
                      {recipe.matched_ingredients.length > 0 && (
                        <div className="mt-3 pt-3 border-t border-gray-100 flex flex-wrap gap-1">
                          {recipe.matched_ingredients.slice(0, MATCHED_INGREDIENT_DISPLAY_LIMIT).map((ingredient, idx) => (
                            <span
                              key={idx}
                              className="px-2 py-0.5 bg-green-100 text-green-700 text-xs rounded-full"
                            >
                              {ingredient}
                            </span>
                          ))}
                          {recipe.matched_ingredients.length > MATCHED_INGREDIENT_DISPLAY_LIMIT && (
                            <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded-full">
                              +{recipe.matched_ingredients.length - MATCHED_INGREDIENT_DISPLAY_LIMIT} more
                            </span>
                          )}
                        </div>
                      )}
                    </div>
                  </Link>
              ))}
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
