class Article < ActiveRecord::Base
  belongs_to :author, counter_cache: true
  has_many :comments
  after_save :update_counter_cache

  scope :five_longest_article_names, -> { order("length(name) DESC").limit(5).pluck(:name) }
  scope :all_names, -> { pluck(:name) }
  scope :articles_with_names_less_than_20_char, -> { where("length(name) < ?", 20) }
  
  private
    def update_counter_cache
      Article.update(self.id, :comments_count => self.comments.length) unless self.comments.length == self.comments_count
    end
  # def self.all_names
  #   pluck(:name)
  # end


  # def self.articles_with_names_less_than_20_char
  #
  # end

  # def self.all_names
  #   all.map do |art|
  #     art.name
  #   end
  # end
  #
  # def self.five_longest_article_names
  #   all.sort_by do |art|
  #     art.name
  #   end.last(5).map do |art|
  #     art.name
  #   end
  # end
  #
  # def self.articles_with_names_less_than_20_char
  #   select do |art|
  #     art.name.length < 20
  #   end
  # end
end
