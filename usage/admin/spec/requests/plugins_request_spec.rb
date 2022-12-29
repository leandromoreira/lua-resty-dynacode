require 'rails_helper'

RSpec.describe "Plugins", type: :request do

  describe "GET /index" do
    it "returns http success" do
      get "/plugins/index"
      expect(response).to have_http_status(:success)
    end
  end

end
