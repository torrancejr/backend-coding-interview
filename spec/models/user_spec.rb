require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }
    it { should validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:password).is_at_least(8) }

    it "rejects invalid username formats" do
      user = build(:user, username: "bad user!")
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("only allows letters, numbers, and underscores")
    end

    it "rejects invalid email formats" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
    end

    it "downcases email before save" do
      user = create(:user, email: "RYAN@Example.COM")
      expect(user.email).to eq("ryan@example.com")
    end
  end

  describe "associations" do
    it { should have_many(:photos) }
    it { should have_many(:albums) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:favorited_photos).through(:favorites) }
  end

  describe "roles" do
    it { should define_enum_for(:role).with_values(member: 0, admin: 1) }
  end

  describe "#photo_count" do
    it "returns the number of photos created by the user" do
      user = create(:user)
      photographer = create(:photographer)
      create_list(:photo, 3, created_by: user, photographer: photographer)
      expect(user.photo_count).to eq(3)
    end
  end
end
