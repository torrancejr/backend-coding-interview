FactoryBot.define do
  factory :photo do
    sequence(:pexels_id) { |n| 2000 + n }
    width { rand(800..6000) }
    height { rand(800..6000) }
    url { Faker::Internet.url }
    alt { Faker::Lorem.sentence }
    avg_color { "##{SecureRandom.hex(3).upcase}" }
    photographer
    created_by { nil }
    src_original { Faker::Internet.url }
    src_medium { Faker::Internet.url }
    src_small { Faker::Internet.url }
    src_tiny { Faker::Internet.url }

    trait :landscape do
      width { 1920 }
      height { 1080 }
    end

    trait :portrait do
      width { 1080 }
      height { 1920 }
    end

    trait :square do
      width { 1080 }
      height { 1080 }
    end

    trait :owned do
      association :created_by, factory: :user
    end
  end
end
