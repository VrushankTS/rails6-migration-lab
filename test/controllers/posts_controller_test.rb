require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should create post" do
    assert_difference("Post.count", 1) do
      post posts_url, params: { post: { title: "Test Title", body: "Test body", published: true } }
    end 

    assert_redirected_to post_url(Post.last)
  end

  test "should not create post with invalid params" do
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { title: "", body: "", published: true } }
    end    

    assert_response :unprocessable_entity
  end

end