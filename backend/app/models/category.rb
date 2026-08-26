class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  # Trim before validating so " Food " cannot slip past the uniqueness check
  # and create a near-duplicate of an existing category.
  normalizes :name, with: ->(name) { name.strip }

  validates :name,
            presence: true,
            length: { maximum: 100 },
            uniqueness: { case_sensitive: false }
end
