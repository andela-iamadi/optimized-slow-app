# Andela Rails Checkpoint #3

This app was originally a really slow one, written to test knowledge of best practices when building a Rails data-intensive application to ensure top-notch performance.


### This was one of the worst performing Rails apps ever.

Previously, the home page takes this long to load:

```bash
...
Article Load (0.5ms)  SELECT "articles".* FROM "articles" WHERE "articles"."author_id" = ?  [["author_id", 3000]]
Article Load (0.5ms)  SELECT "articles".* FROM "articles" WHERE "articles"."author_id" = ?  [["author_id", 3001]]
Rendered author/index.html.erb within layouts/application (9615.5ms)
Completed 200 OK in 9793ms (Views: 7236.5ms | ActiveRecord: 2550.1ms)
```

The view took 7.2 seconds to load. The AR querying took 2.5 second to load. The home page took close to 10 seconds to load. That's not great at all. That's just awful.

The stats page is even worse:

```
bash
Rendered stats/index.html.erb within layouts/application (9.9ms)
Completed 200 OK in 16197ms (Views: 38.0ms | ActiveRecord: 4389.4ms)
```

It took 16 seconds to load and a lot of the time taken isn't even in the ActiveRecord querying or the view. It's the creation of ruby objects that is taking a lot of time. This will be explained in further detail below.

So, **What can we do?**

Well, let's focus on improving the view and the AR querying first!


# Things I implemented in this checkpoint
* indexed all columns that were searched and read from much more frequently than they were written to.
* implemented eager loading vs lazy loading on the right pages. Optimized sql queries using eager loading scopes to limit database queries to the barest minimum.
* replaced Ruby lookups with ActiveRecord methods.
* fixed html_safe issue.
* implemented russian dolls caching technique (nested fragment caching) on the root page.
* Paginated where too many information is being pulled out of the database to be rendered on a page, especially the homepage.

##### Indexed some columns. But what should we index?


Our non-performant app has many opportunities to index. Just look at our associations. There are many foreign keys in our database...

```ruby
class Article < ActiveRecord::Base
  belongs_to :author
  has_many :comments
end
```

##### Ruby vs ActiveRecord

Let's try to get some ids from our Article model.

Look at Ruby:

```ruby
puts Benchmark.measure {Article.select(:id).collect{|a| a.id}}
  Article Load (2.6ms)  SELECT "articles"."id" FROM "articles"
  0.020000   0.000000   0.020000 (  0.021821)
```

The real time is 0.021821 for the Ruby query.

vs ActiveRecord

```ruby
puts Benchmark.measure {Article.pluck(:id)}
   (3.2ms)  SELECT "articles"."id" FROM "articles"
  0.000000   0.000000   0.000000 (  0.006992)
```
The real time is 0.006992 for the AR query. Ruby is about 300% slower.

For example, this code is terribly written in the Author model:

```ruby
def self.most_prolific_writer
  all.sort_by{|a| a.articles.count }.last
end

def self.with_most_upvoted_article
  all.sort_by do |auth|
    auth.articles.sort_by do |art|
      art.upvotes
    end.last
  end.last
end
```

Both methods use Ruby methods (sort_by) instead of ActiveRecord. Let's fix that.

```
scope :most_prolific_writer, -> { order("articles_count DESC").limit(1) }
scope :with_most_upvoted_article, -> { joins(:articles).where("articles.upvotes").order("articles.upvotes DESC").limit(1).pluck(:name) }
```

This minimizes `ActiveRecord` load time as just one query is fired for the same purpose in both cases.

Another example is these ones

```
def self.all_names
  all.map do |art|
    art.name
  end
end

def self.five_longest_article_names
  all.sort_by do |art|
    art.name
  end.last(5).map do |art|
    art.name
  end
end

def self.articles_with_names_less_than_20_char
  select do |art|
    art.name.length < 20
  end
end
```

And they are optimized to:


```
scope :five_longest_article_names, -> { order("length(name) DESC").limit(5).pluck(:name) }
scope :all_names, -> { pluck(:name) }
scope :articles_with_names_less_than_20_char, -> { where("length(name) < ?", 20) }
```

> Key take away? Never use Ruby when you can use ActiveRecord or Optimized queries (eager or lazy loads)

##### html_safe makes it unsafe or safe?.

This is why variable and method naming is important.

In the show.html.erb for articles, we have this code

```ruby
  <% @articles.comments.each do |com| % >
    <%= com.body.html_safe %>
  <% end %>
```

##### What's wrong with it?

The danger is if comment body are user-generated input...which they are.

Any point in your view you render a text directly from database (or any other sort), Rails escapes potentially unsafe scripts and html tags by default.

You only use `html_safe` when you are **ABSOLUTELY SURE** of the source of the text. As a rule of thumb, avoid using it. text marked as `html_safe` will run scripts as if they are local on your server.


##### Conclusion

Our main view took 4 seconds to load

```bash
Rendered author/index.html.erb within layouts/application (5251.7ms)
Completed 200 OK in 5269ms (Views: 4313.1ms | ActiveRecord: 955.6ms)
```

After optimizing, performance improved considerably and now, we have these results

```bash
Rendered author/index.html.erb within layouts/application (12.3ms)
Completed 200 OK in 5269ms (Views: 9.6ms | ActiveRecord: 2.7ms)
```

Any one can learn to code. Performance and simplicity is what separates a good developer from a great one.
