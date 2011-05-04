---
layout: default
---
EasyRedis is a simple ruby framework designed to make using Redis as a database easier.

[Redis](http://redis.io) is a very fast key-value store that supports data structures like lists, sets, and hashes, but because of its simplicity, using Redis to store traditional database data can be somewhat tedious. EasyRedis streamlines this process.


    class Post < EasyRedis::Model
      field :title
      field :body
    end


    p = Post.new
    p.title = "First Post!"
    p.body = "This is my first post."
