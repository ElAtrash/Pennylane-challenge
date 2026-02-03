import { Head, Link } from '@inertiajs/react'
import { RecipeShowProps } from '../../types/recipe'

export default function Show({ recipe }: RecipeShowProps) {
  const totalTime = (recipe.prep_time || 0) + (recipe.cook_time || 0)
  const matchedSet = new Set(recipe.matched_ingredients)

  return (
    <>
      <Head title={`${recipe.title} - Recipe Finder`} />

      <div className="bg-amber-50 min-h-screen">
        <div className="max-w-2xl mx-auto p-4">
          <Link
            href="/"
            className="inline-flex items-center text-amber-600 hover:text-amber-700 mb-4"
          >
            <span className="mr-1">&larr;</span> Back to recipes
          </Link>

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
                  <span>⭐</span>
                  <span className="font-medium">{recipe.ratings.toFixed(1)}</span>
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
                    className={`flex items-start gap-3 py-2 ${matched ? 'text-green-700' : 'text-gray-700'}`}
                  >
                    <span className={`mt-1 w-2 h-2 rounded-full shrink-0 ${matched ? 'bg-green-500' : 'bg-gray-300'}`} />
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
