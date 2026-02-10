require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      {
        username: "testuser",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    context "with valid params" do
      it "creates a user and returns tokens" do
        post "/api/v1/auth/register", params: valid_params

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["user"]["username"]).to eq("testuser")
        expect(body["user"]["email"]).to eq("test@example.com")
        expect(body["tokens"]["access_token"]).to be_present
        expect(body["tokens"]["refresh_token"]).to be_present
        expect(body["tokens"]["token_type"]).to eq("Bearer")
      end

      it "increments the user count" do
        expect { post "/api/v1/auth/register", params: valid_params }.to change(User, :count).by(1)
      end
    end

    context "with invalid params" do
      it "returns errors for missing fields" do
        post "/api/v1/auth/register", params: { username: "test" }

        expect(response).to have_http_status(:unprocessable_content)
        body = JSON.parse(response.body)
        expect(body["error"]["details"]).to be_an(Array)
      end

      it "returns errors for password mismatch" do
        post "/api/v1/auth/register", params: valid_params.merge(password_confirmation: "different")

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns errors for duplicate email" do
        create(:user, email: "test@example.com")
        post "/api/v1/auth/register", params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "login@test.com", password: "password123") }

    context "with valid credentials" do
      it "returns tokens" do
        post "/api/v1/auth/login", params: { email: "login@test.com", password: "password123" }

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["tokens"]["access_token"]).to be_present
        expect(body["user"]["email"]).to eq("login@test.com")
      end
    end

    context "with invalid credentials" do
      it "returns 401 for wrong password" do
        post "/api/v1/auth/login", params: { email: "login@test.com", password: "wrong" }

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body)
        expect(body["error"]["message"]).to eq("Invalid email or password")
      end

      it "returns 401 for nonexistent email" do
        post "/api/v1/auth/login", params: { email: "nobody@test.com", password: "password123" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let(:user) { create(:user) }

    it "returns new tokens from a valid refresh token" do
      refresh_token = JwtService.encode_refresh_token(user.id)
      post "/api/v1/auth/refresh", params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["tokens"]["access_token"]).to be_present
    end

    it "rejects an access token used as refresh" do
      access_token = JwtService.encode_access_token(user.id)
      post "/api/v1/auth/refresh", params: { refresh_token: access_token }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/profile" do
    let(:user) { create(:user) }

    it "returns the user profile when authenticated" do
      get "/api/v1/auth/profile", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["id"]).to eq(user.id)
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/auth/profile"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
