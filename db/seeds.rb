if Rails.env.development?
  Post.create!(title: 'First Post', post: 'First post seed! Very nice.')
  Post.create!(title: 'Second Post', post: "Second post seed! I'm the best huahua")
end
