class MigratePostBodyToActionText < ActiveRecord::Migration[8.1]
  def up
    Post.reset_column_information
    Post.find_each do |post|
      post.update!(body: post.read_attribute(:post).to_s)
    end

    remove_column :posts, :post
  end

  def down
    add_column :posts, :post, :jsonb, null: false, default: ''

    Post.reset_column_information
    Post.find_each do |post|
      post.update_column(:post, post.body.to_plain_text)
    end

    change_column_default :posts, :post, nil
  end
end
