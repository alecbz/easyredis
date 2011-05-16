---
layout: default
---

## Installation

You can just grab the gem and you're good to go:

    $ gem install easyredis

Or, you can get the source with git:

    $ git clone git://github.com/alecbenzer/easyredis.git

and run:

    $ rake manifest
    $ rake build_gemspec
    $ rake install easyredis.gemspec

## Basics

First, create a simple model:

    require 'easyredis'

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
    p2 = Post.find(id)
    p2.title  # => "My First Post"

Or, we can choose our own ids:

    p = Post.new("coolpost")
    p.title = "A Cool Post"
    p.body = "This post has a high level of coolness."

    p2 = Post.find("coolpost")  # this is a very fast lookup
    p2.title  # => "A Cool Post"

We also get a created_at field for free that we can sort by.

    p.created_at              # a ruby Time object
    Post.all :order => :desc  # all posts ordered by descending time
    Post[n]                   # the nth (0-based indexing) post that was created
    
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

    Post.search_by :title, "A common title"  # all posts with this title
    Post.find_by :title, "My First Post"  # just one post

## Implicit References

You may have noticed fields have not been given any types. EasyRedis automatically tracks the type of a field based on the type of data you assign it.

This works for references, too:

    class Comment < EasyRedis::Model
      field :text
      field :post
    end
    
    c = Comment.new
    c.text = "A comment!"
    
    c.post = Post[0]
