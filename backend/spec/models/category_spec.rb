require 'rails_helper'

RSpec.describe Category, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:category, name: "Groceries")).to be_valid
    end

    it "requires a name" do
      category = build(:category, name: "")

      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("can't be blank")
    end

    it "rejects a name longer than the column allows" do
      category = build(:category, name: "a" * 101)

      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("is too long (maximum is 100 characters)")
    end

    it "rejects a duplicate name" do
      create(:category, name: "Groceries")
      category = build(:category, name: "Groceries")

      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("has already been taken")
    end

    it "rejects a duplicate name differing only in case" do
      create(:category, name: "Groceries")

      expect(build(:category, name: "groceries")).not_to be_valid
    end

    it "rejects a duplicate name differing only in surrounding whitespace" do
      create(:category, name: "Groceries")

      expect(build(:category, name: "  Groceries  ")).not_to be_valid
    end
  end

  describe "deleting a category" do
    it "refuses while expenses still reference it" do
      category = create(:category)
      create(:expense, category: category)

      expect(category.destroy).to be(false)
      expect(category.errors[:base]).to include(/Cannot delete record because dependent expenses exist/)
      expect(Category.exists?(category.id)).to be(true)
    end

    it "succeeds once no expenses reference it" do
      category = create(:category)

      expect(category.destroy).to be_truthy
      expect(Category.exists?(category.id)).to be(false)
    end
  end

  describe "normalization" do
    it "strips surrounding whitespace from the name" do
      category = create(:category, name: "  Groceries  ")

      expect(category.name).to eq("Groceries")
    end
  end
end
