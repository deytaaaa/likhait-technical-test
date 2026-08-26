require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    let!(:expense1) { Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.current) }
    let!(:expense2) { Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.current) }

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
      expect(json.map { |e| e["category"] }).to contain_exactly("Food", "Transport")
    end

    it "returns expenses in descending order by expense date" do
      # created_at ascends while date descends, so a list ordered by
      # created_at would come back in exactly the opposite order.
      older = Expense.create!(description: "Old", amount: 10.00, category: food_category,
                              date: Date.current - 10, created_at: 1.minute.ago)
      newer = Expense.create!(description: "New", amount: 20.00, category: food_category,
                              date: Date.current - 2, created_at: Time.current)

      get "/api/expenses"

      json = JSON.parse(response.body)
      ids = json.map { |e| e["id"] }
      expect(ids.index(newer.id)).to be < ids.index(older.id)
      expect(json.map { |e| e["date"] }).to eq(json.map { |e| e["date"] }.sort.reverse)
    end

    it "puts a newly created expense at the top when it has the latest date" do
      newest = Expense.create!(description: "Coffee", amount: 5.00, category: food_category,
                               date: Date.current)

      get "/api/expenses"

      expect(JSON.parse(response.body).first["id"]).to eq(newest.id)
    end

    it "orders expenses sharing a date by most recently created" do
      first = Expense.create!(description: "First", amount: 10.00, category: food_category,
                              date: Date.current, created_at: 2.hours.ago)
      second = Expense.create!(description: "Second", amount: 20.00, category: food_category,
                               date: Date.current, created_at: 1.hour.ago)

      get "/api/expenses"

      ids = JSON.parse(response.body).map { |e| e["id"] }
      expect(ids.index(second.id)).to be < ids.index(first.id)
    end

    context "when filtering by year and month" do
      it "selects on the expense date rather than the creation timestamp" do
        # Entered today, but the money was spent last month: it belongs to
        # last month's view and must not leak into this month's.
        backdated = Expense.create!(description: "Backdated", amount: 30.00, category: food_category,
                                    date: Date.current.prev_month.beginning_of_month,
                                    created_at: Time.current)

        get "/api/expenses", params: { year: backdated.date.year, month: backdated.date.month }

        expect(JSON.parse(response.body).map { |e| e["id"] }).to include(backdated.id)

        get "/api/expenses", params: { year: Date.current.year, month: Date.current.month }

        expect(JSON.parse(response.body).map { |e| e["id"] }).not_to include(backdated.id)
      end

      it "includes expenses dated on the first and last day of the month" do
        first_day = Expense.create!(description: "First day", amount: 10.00, category: food_category,
                                    date: Date.new(2025, 6, 1))
        last_day = Expense.create!(description: "Last day", amount: 20.00, category: food_category,
                                   date: Date.new(2025, 6, 30))

        get "/api/expenses", params: { year: 2025, month: 6 }

        ids = JSON.parse(response.body).map { |e| e["id"] }
        expect(ids).to contain_exactly(last_day.id, first_day.id)
      end
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq(150.5)
      end
    end

    context "with a future date" do
      it "rejects the expense and explains why" do
        expect {
          post "/api/expenses", params: {
            expense: {
              description: "Next week's lunch",
              amount: 50.00,
              category_id: food_category.id,
              date: Date.current + 1
            }
          }, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Date can't be in the future")
      end

      it "still accepts today" do
        post "/api/expenses", params: {
          expense: {
            description: "Lunch today",
            amount: 50.00,
            category_id: food_category.id,
            date: Date.current
          }
        }, as: :json

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "with negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end
end
