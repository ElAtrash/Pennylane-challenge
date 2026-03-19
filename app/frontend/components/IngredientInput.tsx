import { useEffect, useRef, useState } from 'react';

interface IngredientInputProps {
  ingredients: string[];
  onChange: (ingredients: string[]) => void;
}

export default function IngredientInput({ ingredients, onChange }: IngredientInputProps) {
  const [inputValue, setInputValue] = useState('')
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [error, setError] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const debounceRef = useRef<number | null>(null)
  const suggestionRefs = useRef<(HTMLLIElement | null)[]>([])
  const [highlightedIndex, setHighlightedIndex] = useState(-1)

  useEffect(() => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current)
    }

    if (inputValue.length < 2) {
      setSuggestions([])
      setShowSuggestions(false)
      return
    }

    debounceRef.current = window.setTimeout(async () => {
      try {
        const response = await fetch(`/api/ingredients?q=${encodeURIComponent(inputValue)}`)
        const data = await response.json()
        const filtered = data.ingredients.filter(
          (s: string) => !ingredients.includes(s.toLowerCase())
        )
        setSuggestions(filtered)
        setShowSuggestions(filtered.length > 0)
        setHighlightedIndex(-1)
      } catch {
        setSuggestions([])
        setShowSuggestions(false)
      }
    }, 200)

    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current)
      }
    }
  }, [inputValue, ingredients])

  useEffect(() => {
    suggestionRefs.current = suggestionRefs.current.slice(0, suggestions.length)
  }, [suggestions])

  useEffect(() => {
    if (highlightedIndex >= 0 && suggestionRefs.current[highlightedIndex]) {
      suggestionRefs.current[highlightedIndex]?.scrollIntoView({
        block: 'nearest',
        behavior: 'smooth'
      })
    }
  }, [highlightedIndex])

  const addIngredient = (value: string) => {
    const trimmed = value.trim().toLowerCase()

    if (trimmed.length < 2 || !/[a-z]/i.test(trimmed) || ingredients.includes(trimmed)) {
      setError(true)
      setTimeout(() => setError(false), 300)
      return
    }

    onChange([...ingredients, trimmed])
    setInputValue('')
    setShowSuggestions(false)
    setHighlightedIndex(-1)
  }

  const removeIngredient = (index: number) => {
    onChange(ingredients.filter((_, i) => i !== index))
  }

  const clearAll = () => {
    onChange([])
    setInputValue('')
    inputRef.current?.focus()
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (showSuggestions && suggestions.length > 0) {
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setHighlightedIndex(prev => (prev < suggestions.length - 1 ? prev + 1 : prev))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setHighlightedIndex(prev => (prev > 0 ? prev - 1 : -1))
      } else if (e.key === 'Enter' && highlightedIndex !== -1) {
        e.preventDefault()
        addIngredient(suggestions[highlightedIndex])
        return
      } else if (e.key === 'Escape') {
        setShowSuggestions(false)
        return
      }
    }

    if (e.key === 'Enter' && inputValue.trim()) {
      e.preventDefault()
      addIngredient(inputValue)
    }
  }

  const handleSuggestionClick = (suggestion: string) => {
    addIngredient(suggestion)
    setTimeout(() => { inputRef.current?.focus() }, 0)
  }

  const errorClass = error ? 'animate-[shake_0.3s_ease-in-out]' : ''

  return (
    <div className="relative">
      <div
        className={`flex flex-wrap gap-2 p-3 border rounded-lg focus-within:ring-2 focus-within:ring-amber-500 focus-within:border-amber-500 bg-white ${errorClass}`}
        onClick={() => inputRef.current?.focus()}
      >
        {ingredients.map((ingredient, index) => (
          <span
            key={ingredient}
            className="bg-amber-100 text-amber-800 px-3 py-1 rounded-full flex items-center gap-1 text-sm"
          >
            {ingredient}
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation()
                removeIngredient(index)
              }}
              className="hover:text-amber-600 focus:outline-none ml-1"
              aria-label={`Remove ${ingredient}`}
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </span>
        ))}
        <input
          ref={inputRef}
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => suggestions.length > 0 && setShowSuggestions(true)}
          onBlur={() => setTimeout(() => setShowSuggestions(false), 150)}
          placeholder={ingredients.length === 0 ? "Type an ingredient..." : ""}
          className="flex-1 min-w-30 outline-none bg-transparent border-none focus:ring-0"
        />
        {ingredients.length > 0 && (
          <button
            type="button"
            onClick={clearAll}
            className="text-gray-400 hover:text-gray-600 text-sm px-2"
            aria-label="Clear all ingredients"
          >
            Clear all
          </button>
        )}
      </div>

      {showSuggestions && suggestions.length > 0 && (
        <ul className="absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-48 overflow-auto">
          {suggestions.map((suggestion, index) => (
            <li
              key={suggestion}
              ref={(el) => { suggestionRefs.current[index] = el }}
              className={`px-4 py-2 cursor-pointer ${index === highlightedIndex ? 'bg-amber-100' : 'hover:bg-gray-100'
                }`}
              onMouseDown={() => handleSuggestionClick(suggestion)}
            >
              {suggestion}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
