# frozen_string_literal: true

class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.integer :cook_time
      t.integer :prep_time
      t.decimal :ratings, precision: 3, scale: 2
      t.string :category
      t.string :author
      t.string :image
      t.text :ingredients, array: true, default: []
      t.tsvector :ingredients_search_vector

      t.timestamps
    end

    add_index :recipes, :title
    add_index :recipes, :category
    add_index :recipes, :ratings
    add_index :recipes, :ingredients, using: :gin
    add_index :recipes, :ingredients_search_vector, using: :gin

    # SQL Trigger to auto-update the tsvector column since to_tsvector('english', ...) is not immutable
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE FUNCTION recipes_ingredients_search_trigger() RETURNS trigger AS $$
          BEGIN
            NEW.ingredients_search_vector := to_tsvector('english', array_to_string(NEW.ingredients, ' '));
            RETURN NEW;
          END
          $$ LANGUAGE plpgsql IMMUTABLE;

          CREATE TRIGGER recipes_ingredients_search_update
          BEFORE INSERT OR UPDATE OF ingredients ON recipes
          FOR EACH ROW EXECUTE FUNCTION recipes_ingredients_search_trigger();
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP TRIGGER IF EXISTS recipes_ingredients_search_update ON recipes;
          DROP FUNCTION IF EXISTS recipes_ingredients_search_trigger();
        SQL
      end
    end
  end
end
