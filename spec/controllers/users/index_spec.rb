require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #index' do
    context 'when there are users' do
      let!(:user) { User.create!(name: 'loctx', email: 'loctx@nal.vn', password: 'password', gender: :male) }
      # before do
      #   Create usserr
      # end

      # after do

      # end
      it 'returns a successful response' do
        get :index
        expect(response).to have_http_status(:success)
        res = JSON.parse(response.body)
        expect(res['users'].map { |i| i["id"] }).to eq [user.id]
        expect(res['metadata']['total_count']).to eq 1
      end
    end

    # it 'returns a JSON response with users and metadata' do
    #   user = create(:user)
    #   get :index
    #   json_response = JSON.parse(response.body)

    #   expect(json_response['users']).to be_present
    #   expect(json_response['metadata']).to be_present
    #   expect(json_response['metadata']['total_count']).to eq(1)
    # end
  end
end