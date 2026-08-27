class Category < ApplicationRecord
  # :restrict_with_error, not :destroy. The original cascade would have deleted
  # every expense filed under a category the moment that category was removed,
  # silently and unrecoverably. It also contradicted db/init.sql, which
  # declared the foreign key ON DELETE RESTRICT.
  has_many :expenses, dependent: :restrict_with_error

  # Trim before validating so " Food " cannot slip past the uniqueness check
  # and create a near-duplicate of an existing category.
  normalizes :name, with: ->(name) { name.strip }

  validates :name,
            presence: true,
            length: { maximum: 100 },
            uniqueness: { case_sensitive: false }
end
