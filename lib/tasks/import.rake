namespace :photos do
  desc 'Import photos from CSV file (idempotent, safe to run multiple times)'
  task import: :environment do
    file = ENV.fetch('CSV_PATH', Rails.root.join('data/photos.csv'))
    CsvImportService.call(file.to_s, verbose: true)
  end
end
