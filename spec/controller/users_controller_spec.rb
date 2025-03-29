require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) { { username: "john_doe", email: "john@example.com", password: "password123", gender: "male" } }
  let(:invalid_attributes) { { username: "", email: "invalid_email", password: "" } }
  let(:user) { User.create!(valid_attributes) }

  describe "GET #index" do
    it "should return all users when requested" do
      User.create!(valid_attributes)
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET #show" do
    it "should return user details when user exists" do
      user
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["username"]).to eq(user.username)
    end

    it "should return not found when user does not exist" do
      invalid_id = 999
      get :show, params: { id: invalid_id }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "User not found" })
    end
  end

  describe "POST #create" do
    it "should create user when valid params are provided" do
      user_params = valid_attributes
      post :create, params: { user: user_params }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["username"]).to eq("john_doe")
    end

    it "should return unprocessable entity when invalid params are provided" do
      user_params = invalid_attributes
      post :create, params: { user: user_params }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("username")
    end
  end

  describe "PATCH #update" do
    it "should update user when valid params are provided" do
      user
      updated_params = { username: "new_john" }
      patch :update, params: { id: user.id, user: updated_params }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["username"]).to eq("new_john")
    end

    it "should return unprocessable entity when invalid params are provided" do
      user
      updated_params = { username: "" }
      patch :update, params: { id: user.id, user: updated_params }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("username")
    end

    it "should return not found when user does not exist" do
      invalid_id = 999
      patch :update, params: { id: invalid_id, user: { username: "new_name" } }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "User not found" })
    end
  end

  describe "DELETE #destroy" do
    it "should delete user when user exists" do
      user
      delete :destroy, params: { id: user.id }
      expect(response).to have_http_status(:no_content)
      expect(User.exists?(user.id)).to be_falsey
    end

    it "should return not found when user does not exist" do
      invalid_id = 999
      delete :destroy, params: { id: invalid_id }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "User not found" })
    end
  end
end
