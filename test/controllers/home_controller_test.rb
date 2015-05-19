require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get query" do
    get :query
    assert_response :success
  end

  test "should get query_results" do
    get :query_results
    assert_response :success
  end

end
