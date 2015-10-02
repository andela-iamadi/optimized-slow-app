class AddIndexToArticle < ActiveRecord::Migration
  def change
    add_index :articles, :author_id, name: "index_articles_on_author_id", unique: false
    add_index :comments, :article_id, name: "index_comments_on_article_id", unique: false
  end
end
