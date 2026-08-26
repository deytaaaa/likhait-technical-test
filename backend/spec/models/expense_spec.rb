require 'rails_helper'

RSpec.describe Expense, type: :model do
  describe "date validation" do
    it "is valid with today's date" do
      expect(build(:expense, date: Date.current)).to be_valid
    end

    it "is valid with a past date" do
      expect(build(:expense, date: Date.current - 30)).to be_valid
    end

    it "requires a date" do
      expense = build(:expense, date: nil)

      expect(expense).not_to be_valid
      expect(expense.errors[:date]).to include("can't be blank")
    end

    it "rejects tomorrow" do
      expense = build(:expense, date: Date.current + 1)

      expect(expense).not_to be_valid
      expect(expense.errors[:date]).to include("can't be in the future")
    end

    it "rejects a far future date" do
      expect(build(:expense, date: Date.current + 365)).not_to be_valid
    end

    it "rejects a future date on update as well as create" do
      expense = create(:expense, date: Date.current)

      expect(expense.update(date: Date.current + 1)).to be(false)
      expect(expense.reload.date).to eq(Date.current)
    end
  end
end
