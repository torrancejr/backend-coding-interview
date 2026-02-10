# Seed the database with CSV data and a demo user.
#
# Run: rails db:seed
#

# Only seed in development (tests use factories)
return unless Rails.env.development?

puts 'Seeding database...'

# Import photos from CSV
CsvImportService.call(Rails.root.join('data/photos.csv').to_s, verbose: true)

# Create a demo admin user for testing
unless User.exists?(email: 'admin@clever.com')
  User.create!(
    username: 'admin',
    email: 'admin@clever.com',
    password: 'password123',
    password_confirmation: 'password123',
    role: :admin,
    bio: 'Demo admin user'
  )
  puts 'Created demo admin: admin@clever.com / password123'
end

puts 'Seeding complete!'
