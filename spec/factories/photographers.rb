FactoryBot.define do
  factory :photographer do
    sequence(:pexels_id) { |n| 1000 + n }
    name { Faker::Name.name }
    url { Faker::Internet.url }
  end
end
