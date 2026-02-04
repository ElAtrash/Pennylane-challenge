# OmNom - Find recipes by ingredients

## Project Overview

Rails 8 web application that helps users find recipes based on ingredients they have at home

**Core Problem**: User enters ingredients -> system finds and ranks recipes they can make

## Live Demo

[Try it live on Fly.io](https://omnom.fly.dev)

## Tech Stack

- **Backend**: Ruby on Rails 8, PostgreSQL
- **Frontend**: React + TypeScript via Inertia.js
- **Styling**: Tailwind CSS
- **Build**: Vite
- **Testing**: RSpec
- **Pagination**: Pagy

## Core Features

1. Search recipes by ingredients (free-form text input)
2. Display ingredient match count (X/Y ingredients you have)
3. Smart ranking: match score -> coverage score -> fewer ingredients -> higher ratings
4. Pagination with 21 recipes per page
5. Featured recipes view when not searching
6. Intuitive UX (autocomplete, clear all, input validation)

## User Stories

### 1. Search recipes by ingredients

> As a user, I want to enter the ingredients I have at home so that I can find recipes I can make without going to the store.

**Acceptance Criteria:**

- User can type and add multiple ingredients
- System searches across matching recipes
- Multi-word ingredient matching (e.g.: "olive oil")
- Support for hyphenated versions of ingredients (e.g.: "self-rising flour" is treated the same as "self rising flour")
- Autocomplete suggestions

### 2. View ingredient match coverage

> As a user, I want to see recipes where I already have most of its ingredients.

**Acceptance Criteria:**

- Results ranked by match coverage (% of recipe ingredients user has)
- Shows "X/Y ingredients" on each recipe card
- Matched ingredients highlighted with green chips

### 3. Browse recipe details

> As a user, I want to view the full details of a recipe including all ingredients and preparation steps so I can decide if I want to make it.

**Acceptance Criteria:**

- Full ingredient list with matched items highlighted
- Prep time, cook time, and rating visible
- Easy navigation back to search results with filters preserved
