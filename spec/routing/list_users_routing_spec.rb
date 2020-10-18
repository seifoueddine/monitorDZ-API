require "rails_helper"

RSpec.describe ListUsersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/list_users").to route_to("list_users#index")
    end

    it "routes to #show" do
      expect(get: "/list_users/1").to route_to("list_users#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/list_users").to route_to("list_users#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/list_users/1").to route_to("list_users#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/list_users/1").to route_to("list_users#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/list_users/1").to route_to("list_users#destroy", id: "1")
    end
  end
end
