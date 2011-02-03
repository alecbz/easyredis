# EasyRedis

EasyRedis is a simple ruby framework designed to make using Redis as a database simpler.

Redis is a very fast key-value store that supports lists, (sorted) sets, and hashes, but because of its simplicity, using Redis to store traditional database data can be somewhat tedius. EasyRedis streamlines this process.

## Code Samples

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

We can also tell EasyRedis to optimize sorting and search on certain fields. If we had redefined Post like:

    class Post < EasyRedis::Model
      field :title
      field :body

      sort_on :title
    end

We can now retrive posts with things like:

    Post.sort_by :title, :order => :desc
