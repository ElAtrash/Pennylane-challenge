# Recipe Finder

## Project Overview

Rails 8 web application that helps users find recipes based on ingredients they have at home

**Core Problem**: User enters ingredients -> system finds and ranks recipes they can make

## Tech Stack

- **Backend**: Ruby on Rails 8, PostgreSQL
- **Frontend**: React + TypeScript via Inertia.js
- **Styling**: Tailwind CSS
- **Build**: Vite
- **Testing**: RSpec

## Core Features
1. Search recipes by ingredients (free-form text input)
2. Display the number of user ingredients has in a recipe
3. Rank by: coverage score -> match score -> total ingredients
4. Simple UI with intuitive UX (autocomplete, clear all, etc.)
