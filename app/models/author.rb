class Author < ActiveRecord::Base
  has_many :articles
  after_save :update_counter_cache
  WillPaginate.per_page = 21
  scope :most_prolific_writer, -> { order("articles_count DESC").limit(1) }
  scope :with_most_upvoted_article, -> { joins(:articles).where("articles.upvotes").order("articles.upvotes DESC").limit(1).pluck(:name) }

  def self.generate_authors(count=1000)
    count.times do
      Fabricate(:author)
    end
    first.articles << Article.create(name: "some commenter", body: "some body")
  end

private
  def update_counter_cache
    # update_attribute(:articles_count, self.articles.length) unless self.articles.length == self.articles_count
    Author.update(self.id, :articles_count => self.articles.length) unless self.articles.length == self.articles_count
  end

    # scope :most_prolific_writer, -> { select("author_id, count(id) as article_count").group("author_id").order =>("article_count DESC").limit(1) }
    # scope :with_most_upvoted_article_2, -> { Article.order("upvotes DESC").first.author.name }

  #
  # def self.most_prolific_writer
  #   all.sort_by{|a| a.articles.count }.last
  # end

  # def self.with_most_upvoted_article
  #   all.sort_by do |auth|
  #     auth.articles.sort_by do |art|
  #       art.upvotes
  #     end.last
  #   end.last.name
  # end

end
