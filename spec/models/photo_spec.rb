require "rails_helper"

RSpec.describe Photo, type: :model do
  describe "validations" do
    subject { build(:photo) }

    it { should validate_presence_of(:width) }
    it { should validate_presence_of(:height) }
    it { should validate_presence_of(:url) }
    it { should validate_numericality_of(:width).is_greater_than(0) }
    it { should validate_numericality_of(:height).is_greater_than(0) }
    it { should validate_uniqueness_of(:pexels_id).allow_nil }

    it "validates hex color format" do
      photo = build(:photo, avg_color: "not-a-color")
      expect(photo).not_to be_valid
      expect(photo.errors[:avg_color]).to include("must be a valid hex color")
    end

    it "accepts valid hex colors" do
      photo = build(:photo, avg_color: "#FF00AA")
      expect(photo).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:photographer) }
    it { should belong_to(:created_by).class_name("User").optional }
    it { should have_many(:favorites).dependent(:destroy) }
  end

  describe "scopes" do
    let(:photographer) { create(:photographer) }

    it ".landscape returns photos wider than tall" do
      landscape = create(:photo, :landscape, photographer: photographer)
      portrait = create(:photo, :portrait, photographer: photographer)
      expect(Photo.landscape).to include(landscape)
      expect(Photo.landscape).not_to include(portrait)
    end

    it ".portrait returns photos taller than wide" do
      portrait = create(:photo, :portrait, photographer: photographer)
      landscape = create(:photo, :landscape, photographer: photographer)
      expect(Photo.portrait).to include(portrait)
      expect(Photo.portrait).not_to include(landscape)
    end

    it ".search matches alt text (case-insensitive)" do
      beach = create(:photo, alt: "A beautiful beach sunset", photographer: photographer)
      city = create(:photo, alt: "City skyline at night", photographer: photographer)
      expect(Photo.search("beach")).to include(beach)
      expect(Photo.search("beach")).not_to include(city)
    end

    it ".by_color filters by exact avg_color" do
      red = create(:photo, avg_color: "#FF0000", photographer: photographer)
      blue = create(:photo, avg_color: "#0000FF", photographer: photographer)
      expect(Photo.by_color("#FF0000")).to include(red)
      expect(Photo.by_color("#FF0000")).not_to include(blue)
    end
  end

  describe "#orientation" do
    let(:photographer) { create(:photographer) }

    it "returns 'landscape' when width > height" do
      photo = build(:photo, width: 1920, height: 1080, photographer: photographer)
      expect(photo.orientation).to eq("landscape")
    end

    it "returns 'portrait' when height > width" do
      photo = build(:photo, width: 1080, height: 1920, photographer: photographer)
      expect(photo.orientation).to eq("portrait")
    end

    it "returns 'square' when width == height" do
      photo = build(:photo, width: 1080, height: 1080, photographer: photographer)
      expect(photo.orientation).to eq("square")
    end
  end

  describe "#favorited_by?" do
    let(:user) { create(:user) }
    let(:photo) { create(:photo) }

    it "returns true when the user has favorited the photo" do
      create(:favorite, user: user, photo: photo)
      expect(photo.favorited_by?(user)).to be true
    end

    it "returns false when the user has not favorited" do
      expect(photo.favorited_by?(user)).to be false
    end

    it "returns false when user is nil" do
      expect(photo.favorited_by?(nil)).to be false
    end
  end
end
