# EasyRedis

EasyRedis is a simple ruby framework designed to make using Redis as a database simpler.

Redis is a very fast key-value store that supports data structures like lists, (sorted) sets, and hashes, but because of its simplicity, using Redis to store traditional database data can be somewhat tedious. EasyRedis streamlines this process.

## Basics

First, create a simple model:

    require 'easy_redis'

    class Post < EasyRedis::Model
      field :title
      field :body
    end

    EasyRedis.connect

This creates a Post model and connects to a redis server running on localhost on the default port (you can pass options to EasyRedis.connect like you would to Redis.new)

We can now make post objects:

    p = Post.new
    p.title = "My First Post"
    p.body = "This is my very first post!"

Posts are automatically given ids that we can then use to retrive them:

    id = p.id
    p = Post[id]  # or Post.find(id)
    p.title  # => "My First Post"

We also get a created_at field for free that we can sort by.

    p.created_at  # a ruby Time object
    Post.all  # get all posts, ordered by creation time
    Post.all :order => :desc  # specifying an order option
    
## Searching and Sorting

We can also tell EasyRedis to optimize sorting and searching on certain fields. If we had defined Post as:

    class Post < EasyRedis::Model
      field :title
      field :body

      sort_on :title
    end

We can now sort our posts by title:

    Post.sort_by :title, :order => :desc

And also search:

    Post.search_by(:title,"A common title")  # all posts with this title
    Post.find_by(:title,"My First Post")  # just one post
