class AddCountToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :comments_count, :integer, default: 0
    add_column :authors, :articles_count, :integer, default: 0
  end
end
