require 'rails_helper'

RSpec.describe "Api::Categories", type: :request do
  describe "GET /api/categories" do
    let!(:food) { Category.create!(name: "Food") }
    let!(:transport) { Category.create!(name: "Transport") }
    let!(:supplies) { Category.create!(name: "Supplies") }

    it "returns all categories" do
      get "/api/categories"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json.map { |c| c["name"] }).to include("Food", "Transport", "Supplies")
    end

    it "returns categories in alphabetical order" do
      get "/api/categories"

      json = JSON.parse(response.body)
      expect(json.map { |c| c["name"] }).to eq([ "Food", "Supplies", "Transport" ])
    end
  end

  describe "POST /api/categories" do
    context "with valid parameters" do
      it "creates the category and returns it" do
        expect {
          post "/api/categories", params: { category: { name: "Groceries" } }, as: :json
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Groceries")
        expect(json["id"]).to be_present
      end

      it "strips surrounding whitespace from the name" do
        post "/api/categories", params: { category: { name: "  Groceries  " } }, as: :json

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["name"]).to eq("Groceries")
      end
    end

    context "with invalid parameters" do
      it "rejects a blank name" do
        expect {
          post "/api/categories", params: { category: { name: "" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Name can't be blank")
      end

      it "rejects a duplicate name" do
        Category.create!(name: "Groceries")

        expect {
          post "/api/categories", params: { category: { name: "Groceries" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Name has already been taken")
      end

      it "rejects a duplicate name differing only in case" do
        Category.create!(name: "Groceries")

        expect {
          post "/api/categories", params: { category: { name: "GROCERIES" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects a name longer than 100 characters" do
        expect {
          post "/api/categories", params: { category: { name: "a" * 101 } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
