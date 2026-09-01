Post.delete_all

posts = [
  {
    title: "Rails 6 baseline",
    body: "This post proves the Rails 6 app is booting with PostgreSQL and a valid data model.",
    published: true
  },
  {
    title: "Migration lab",
    body: "This seed data gives us a realistic app baseline before upgrading to Rails 7 and Rails 8.",
    published: true
  },
  {
    title: "Draft example",
    body: "A draft record shows that unpublished posts can still be stored for migration testing.",
    published: false
  }
]

Post.create!(posts)

puts "Created #{Post.count} posts."
