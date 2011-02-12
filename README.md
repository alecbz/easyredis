# EasyRedis

EasyRedis is a simple ruby framework designed to make using Redis as a database simpler.

Redis is a very fast key-value store that supports data structures like lists, (sorted) sets, and hashes, but because of its simplicity, using Redis to store traditional database data can be somewhat tedious. EasyRedis streamlines this process.

## Installation

You can just grab the gem and you're good to go:

    $ gem install easyredis

Or, you can get the source with git:

    $ git clone git://github.com/alecbenzer/easyredis.git

or just download and extract a tar archive with the Downloads button.

Once you have the source, you can run:

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

    p.created_at  # a ruby Time object
    Post.all  # get all posts, ordered by creation time
    Post.all :order => :desc  # specifying an order option
    Post[41]  # the 42nd (0-based indexing) post that was created
    
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

## Text Search and Completions

We could have defined Post like this:

    class Post < EasyRedis::Model
      field :title
      field :body

      text_search :title
    end

Now we can perform text searches and completions against our title field:

    Post.matches(:title,"Fir")  # titles that begin with "Fir"
    Post.match(:title,"First")  # posts whose titles contain "First"
