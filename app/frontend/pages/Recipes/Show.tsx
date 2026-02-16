import { Head, Link } from '@inertiajs/react'
import { RecipeShowProps } from '../../types/recipe'

export default function Show({ recipe, search_ingredients = [] }: RecipeShowProps) {
  const totalTime = (recipe.prep_time || 0) + (recipe.cook_time || 0)
  const matchedSet = new Set(recipe.matched_ingredients)

  const backUrl = search_ingredients.length > 0
    ? `/?${search_ingredients.map(i => `ingredients[]=${encodeURIComponent(i)}`).join('&')}`
    : '/'

  return (
    <>
      <Head title={`${recipe.title} - OmNom`} />

      <div className="bg-amber-50 min-h-screen">
        <div className="max-w-2xl mx-auto p-4">
          <Link
            href={backUrl}
            className="inline-flex items-center text-amber-600 hover:text-amber-700 mb-4"
          >
            <span className="mr-1">&larr;</span> Back to recipes
          </Link>

          {recipe.image ? (
            <div className="mb-6">
              <img
                src={recipe.image}
                alt={recipe.title}
                className="w-full h-64 md:h-96 object-cover rounded-xl shadow-lg"
                onError={(e) => {
                  e.currentTarget.style.display = 'none'
                }}
              />
            </div>
          ) : (
            <div className="mb-6">
              <div className="w-full h-64 md:h-96 bg-linear-to-br from-amber-100 to-amber-200 rounded-xl shadow-lg flex items-center justify-center">
                <svg className="w-24 h-24 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
            </div>
          )}

          <div className="bg-white rounded-xl p-6 border mb-4">
            <h1 className="text-2xl font-bold mb-3">{recipe.title}</h1>

            <div className="flex flex-wrap items-center gap-2 mb-4">
              {recipe.category && (
                <span className="px-3 py-1 bg-amber-100 text-amber-700 text-sm rounded-full">
                  {recipe.category}
                </span>
              )}
              {recipe.author && (
                <span className="px-3 py-1 bg-gray-100 text-gray-600 text-sm rounded-full">
                  by {recipe.author}
                </span>
              )}
            </div>

            <div className="flex flex-wrap gap-4 text-sm text-gray-600">
              {recipe.ratings !== null && (
                <div className="flex items-center gap-1">
                  <span className="inline-flex items-center gap-1 text-amber-600 font-semibold">
                    <svg className="w-4 h-4 fill-current" viewBox="0 0 20 20">
                      <path d="M10 15l-5.878 3.09 1.123-6.545L.489 6.91l6.572-.955L10 0l2.939 5.955 6.572.955-4.756 4.635 1.123 6.545z" />
                    </svg>
                    {recipe.ratings!.toFixed(1)}
                  </span>
                </div>
              )}
              {recipe.prep_time !== null && (
                <div>
                  <span className="text-gray-400">Prep:</span> {recipe.prep_time} min
                </div>
              )}
              {recipe.cook_time !== null && (
                <div>
                  <span className="text-gray-400">Cook:</span> {recipe.cook_time} min
                </div>
              )}
              {totalTime > 0 && (
                <div>
                  <span className="text-gray-400">Total:</span> {totalTime} min
                </div>
              )}
            </div>
          </div>

          <div className="bg-white rounded-xl p-6 border">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold">
                Ingredients
                <span className="text-gray-400 font-normal ml-2">({recipe.ingredients.length})</span>
              </h2>
              {matchedSet.size > 0 && (
                <span className="text-sm text-green-600 font-medium">
                  You have {matchedSet.size} of {recipe.ingredients.length}
                </span>
              )}
            </div>

            <ul className="space-y-2">
              {recipe.ingredients.map((ingredient, idx) => {
                const matched = matchedSet.has(ingredient)
                return (
                  <li
                    key={idx}
                    className={`flex items-center gap-3 py-2 ${matched ? 'text-green-700' : 'text-gray-700'}`}
                  >
                    <span className={`w-2 h-2 rounded-full shrink-0 ${matched ? 'bg-green-500' : 'bg-gray-300'}`} />
                    <span>{ingredient}</span>
                  </li>
                )
              })}
            </ul>
          </div>
        </div>
      </div>
    </>
  )
}
