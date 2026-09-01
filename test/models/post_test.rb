require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "valid with title and body" do
    post = Post.new(title: "Test Post", body: "Test Body")
    assert post.valid?
  end

  test "valid without title" do 
    post = Post.new(title: nil,  body: "Test Body")
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "valid without body" do
    post = Post.new(title: "Test Title", body: nil)
    assert_not post.valid?
    assert_includes post.errors[:body], "can't be blank"
  end

end
