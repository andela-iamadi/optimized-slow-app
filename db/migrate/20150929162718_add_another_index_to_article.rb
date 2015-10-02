class AddAnotherIndexToArticle < ActiveRecord::Migration
  def change
    add_index :articles, :name, name: "index_articles_on_name", unique: false    
  end
end
