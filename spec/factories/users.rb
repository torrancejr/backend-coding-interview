FactoryBot.define do
  factory :user do
    username { Faker::Internet.unique.username(specifier: 5..20, separators: %w[_]) }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { :member }

    trait :admin do
      role { :admin }
    end
  end
end
