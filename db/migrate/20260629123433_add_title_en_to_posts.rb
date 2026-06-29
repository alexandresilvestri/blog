class AddTitleEnToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :title_en, :string
  end
end
