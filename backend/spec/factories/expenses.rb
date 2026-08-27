FactoryBot.define do
  factory :expense do
    description { "Team lunch" }
    amount { "9.99" }
    date { Date.current }
    association :category
  end
end
