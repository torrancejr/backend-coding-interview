FactoryBot.define do
  factory :album do
    name { Faker::Lorem.words(number: 3).join(" ").titleize }
    description { Faker::Lorem.sentence }
    association :owner, factory: :user
    is_public { false }

    trait :public_album do
      is_public { true }
    end
  end
end
