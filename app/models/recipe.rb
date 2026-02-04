class Recipe < ApplicationRecord
  validates :title, presence: true

  scope :featured, -> { order(ratings: :desc, title: :asc) }
end
