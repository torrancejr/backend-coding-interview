require "rails_helper"

RSpec.describe "Photos API", type: :request do
  let(:user) { create(:user) }
  let(:photographer) { create(:photographer) }
  let!(:photos) { create_list(:photo, 5, photographer: photographer) }

  describe "GET /api/v1/photos" do
    it "returns paginated photos" do
      get "/api/v1/photos"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["photos"].length).to eq(5)
      expect(body["meta"]).to include("current_page", "total_pages", "total_count", "per_page")
    end

    it "supports search by alt text" do
      create(:photo, alt: "unique beach sunset photo", photographer: photographer)
      get "/api/v1/photos", params: { search: "beach sunset" }

      body = JSON.parse(response.body)
      expect(body["photos"].length).to eq(1)
      expect(body["photos"].first["alt"]).to include("beach sunset")
    end

    it "supports orientation filter" do
      create(:photo, :landscape, photographer: photographer)
      create(:photo, :portrait, photographer: photographer)

      get "/api/v1/photos", params: { orientation: "landscape" }
      body = JSON.parse(response.body)
      body["photos"].each do |photo|
        expect(photo["orientation"]).to eq("landscape")
      end
    end

    it "supports photographer name filter" do
      special = create(:photographer, name: "Special Person")
      create(:photo, photographer: special, alt: "special photo")

      get "/api/v1/photos", params: { photographer: "Special" }
      body = JSON.parse(response.body)
      expect(body["photos"].length).to eq(1)
    end

    it "supports pagination params" do
      get "/api/v1/photos", params: { page: 1, per_page: 2 }

      body = JSON.parse(response.body)
      expect(body["photos"].length).to eq(2)
      expect(body["meta"]["total_count"]).to eq(5)
      expect(body["meta"]["total_pages"]).to eq(3)
    end

    it "supports sort by width descending" do
      get "/api/v1/photos", params: { sort: "-width" }

      body = JSON.parse(response.body)
      widths = body["photos"].map { |p| p["width"] }
      expect(widths).to eq(widths.sort.reverse)
    end

    context "when authenticated" do
      it "includes is_favorited flag" do
        fav_photo = photos.first
        create(:favorite, user: user, photo: fav_photo)

        get "/api/v1/photos", headers: auth_headers(user)

        body = JSON.parse(response.body)
        favorited = body["photos"].find { |p| p["id"] == fav_photo.id }
        expect(favorited["is_favorited"]).to be true
      end
    end
  end

  describe "GET /api/v1/photos/:id" do
    it "returns full photo details" do
      get "/api/v1/photos/#{photos.first.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["photo"]["id"]).to eq(photos.first.id)
      expect(body["photo"]["src"]).to include("original")
      expect(body["photo"]["photographer"]).to include("name")
    end

    it "returns 404 for nonexistent photo" do
      get "/api/v1/photos/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/photos" do
    let(:valid_params) do
      {
        width: 1920,
        height: 1080,
        url: "https://example.com/photo.jpg",
        alt: "Test photo",
        photographer_id: photographer.id
      }
    end

    it "creates a photo when authenticated" do
      post "/api/v1/photos", params: valid_params, headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["photo"]["alt"]).to eq("Test photo")
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/photos", params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 for invalid params" do
      post "/api/v1/photos", params: { width: -1 }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/v1/photos/:id" do
    let(:owned_photo) { create(:photo, created_by: user, photographer: photographer) }

    it "allows the owner to update" do
      put "/api/v1/photos/#{owned_photo.id}", params: { alt: "Updated" }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(owned_photo.reload.alt).to eq("Updated")
    end

    it "forbids non-owners from updating" do
      other_user = create(:user)
      put "/api/v1/photos/#{owned_photo.id}", params: { alt: "Hacked" }, headers: auth_headers(other_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "allows admins to update any photo" do
      admin = create(:user, :admin)
      put "/api/v1/photos/#{owned_photo.id}", params: { alt: "Admin edit" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/photos/:id" do
    let!(:owned_photo) { create(:photo, created_by: user, photographer: photographer) }

    it "allows the owner to delete" do
      expect {
        delete "/api/v1/photos/#{owned_photo.id}", headers: auth_headers(user)
      }.to change(Photo, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "forbids non-owners from deleting" do
      other_user = create(:user)
      delete "/api/v1/photos/#{owned_photo.id}", headers: auth_headers(other_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/photos/:id/favorite" do
    it "favorites a photo" do
      post "/api/v1/photos/#{photos.first.id}/favorite", headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      expect(user.favorites.count).to eq(1)
    end

    it "is idempotent (favoriting twice doesn't error)" do
      create(:favorite, user: user, photo: photos.first)
      post "/api/v1/photos/#{photos.first.id}/favorite", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/photos/:id/unfavorite" do
    it "unfavorites a photo" do
      create(:favorite, user: user, photo: photos.first)
      delete "/api/v1/photos/#{photos.first.id}/unfavorite", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.favorites.count).to eq(0)
    end

    it "returns 404 if not favorited" do
      delete "/api/v1/photos/#{photos.first.id}/unfavorite", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end
end
