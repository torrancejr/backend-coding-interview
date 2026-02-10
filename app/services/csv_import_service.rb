require 'csv'

# Imports photo data from the provided CSV file.
# Handles:
#   - Photographer upsert (find_or_create by pexels_id)
#   - Photo upsert (find_or_create by pexels_id)
#   - Idempotent: safe to run multiple times
#
# Usage:
#   CsvImportService.call("data/photos.csv")
#   CsvImportService.call("data/photos.csv", verbose: true)
#
class CsvImportService
  attr_reader :file_path, :verbose, :stats

  def self.call(file_path, verbose: false)
    new(file_path, verbose: verbose).call
  end

  def initialize(file_path, verbose: false)
    @file_path = file_path
    @verbose = verbose
    @stats = { photographers_created: 0, photographers_found: 0, photos_created: 0, photos_found: 0, errors: [] }
  end

  def call
    raise ArgumentError, "CSV file not found: #{file_path}" unless File.exist?(file_path)

    log "Importing photos from #{file_path}..."

    ActiveRecord::Base.transaction do
      CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
        import_row(row)
      end
    end

    log 'Import complete!'
    log "  Photographers: #{stats[:photographers_created]} created, #{stats[:photographers_found]} existing"
    log "  Photos: #{stats[:photos_created]} created, #{stats[:photos_found]} existing"
    log "  Errors: #{stats[:errors].length}" if stats[:errors].any?

    stats
  end

  private

  def import_row(row)
    photographer = find_or_create_photographer(row)
    find_or_create_photo(row, photographer)
  rescue StandardError => e
    stats[:errors] << { pexels_id: row[:id], error: e.message }
    log "  ERROR importing photo #{row[:id]}: #{e.message}"
  end

  def find_or_create_photographer(row)
    photographer = Photographer.find_by(pexels_id: row[:photographer_id].to_i)

    if photographer
      stats[:photographers_found] += 1
      return photographer
    end

    photographer = Photographer.create!(
      pexels_id: row[:photographer_id].to_i,
      name: row[:photographer],
      url: row[:photographer_url]
    )
    stats[:photographers_created] += 1
    log "  Created photographer: #{photographer.name}"
    photographer
  end

  def find_or_create_photo(row, photographer)
    existing = Photo.find_by(pexels_id: row[:id].to_i)

    if existing
      stats[:photos_found] += 1
      log "  Photo #{row[:id]} already exists, skipping"
      return existing
    end

    photo = Photo.create!(
      pexels_id: row[:id].to_i,
      width: row[:width].to_i,
      height: row[:height].to_i,
      url: row[:url],
      avg_color: row[:avg_color],
      alt: row[:alt],
      src_original: row[:srcoriginal],
      src_large2x: row[:srclarge2x],
      src_large: row[:srclarge],
      src_medium: row[:srcmedium],
      src_small: row[:srcsmall],
      src_portrait: row[:srcportrait],
      src_landscape: row[:srclandscape],
      src_tiny: row[:srctiny],
      photographer: photographer,
      created_by: nil # CSV imports have no user owner
    )
    stats[:photos_created] += 1
    log "  Created photo: #{photo.pexels_id} - #{photo.alt&.truncate(50)}"
    photo
  end

  def log(message)
    puts message if verbose
  end
end
