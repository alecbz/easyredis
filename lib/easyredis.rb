# EasyRedis is a simple ruby framework designed to make using Redis as a database simpler.
#
# Redis is a very fast key-value store that supports data structures like lists, (sorted) sets, and hashes, but because of its simplicity, using Redis to store traditional database data can be somewhat tedious. EasyRedis streamlines this process.
#
# Author:: Alec Benzer (mailto:alecbenzer@gmail.com)


require 'redis'
require 'set'
require 'active_support/inflector'


# main EasyRedis module which
# holds all classes and helper methods
module EasyRedis
  
  # generate a 'score' for a string
  # used for storing it in a sorted set
  def self.string_score(str)
    str = str.downcase
    mult = 1.0
    scr = 0.0
    str.each_byte do |b|
      mult /= 27
      scr += (b-'a'.ord+1)*mult
    end
    scr
  end

  # gets a score for a generic object
  #
  # uses string_score if the object is a string
  # and just returns the object otherwise (presumably its a number)
  def self.score(obj)
    if obj.is_a? String
      string_score(obj)
    else
      obj
    end
  end

  # access the redis object
  def self.redis
    @redis
  end

  # connect to a redis server
  def self.connect(options = {})
    @redis = Redis.new(options)
  end

  # exception that indicates that the given field has not been indexed for sorting/searching
  class FieldNotSortable < RuntimeError
    def initialize(field)
      @message = "field '#{field.to_s}' not sortable"
    end
    
    def to_s
      @message
    end
  end

  # exception that indicated an unknown ordering option was encountered
  class UnknownOrderOption < RuntimeError
    def initialize(opt)
      @message = "unknown order option '#{opt}'"
    end

    def to_s
      @message
    end
  end

  # class representing a sort
  class Sort
    include Enumerable

    def initialize(field,order,klass)
      raise EasyRedis::FieldNotSortable, field  unless @klass.sortable?(field) 
      raise EasyRedis::UnknownOrderOption, options[:order]  unless [:asc,:desc].member? options[:order]
      @field = field
      @order = order
      @klass = klass
    end

    def [](index,limit=nil)
      if limit
        offset = index
        self[offset...(offset+limit)]
      elsif index.is_a? Range
        a = index.begin
        b = index.end
        b -= 1 if index.exclude_end?
        ids = []
        if @order == :asc
          ids = EasyRedis.redis.zrange(@klass.sort_prefix(@field),a,b)
        elsif @order == :desc
          ids = EasyRedis.redis.zrevrange(@klass.sort_prefix(@field),a,b)
        end
        ids.map{|i|@klass.new(i)}
      elsif index.is_a? Integer
        self[index..index].first
      end
    end

    def each
      self[0..-1].each { |o| yield o }
    end

    def count
      EasyRedis.zcard(@klass.sort_prefix(@field))
    end

    def first(n = nil)
      if n
        self[0,n]
      else
        self[0]
      end
    end

    def inspect
      "#<EasyRedis::Sort model=#{@klass.name}, field=#{@field.to_s}, order=#{@order.to_s}>"
    end

  end


  # class representing a data model
  # you want to store in redis
  class Model

    # add a field to the model
    def self.field(name)
      name = name.to_s
      getter = name
      setter = name + "="
      instance_var = '@' + name

      define_method getter.to_sym do
        prev = instance_variable_get(instance_var)
        if prev
          prev
        else
          instance_variable_set(instance_var,EasyRedis.redis.hget(key_name,name))
        end
      end

      define_method setter.to_sym do |val|
        EasyRedis.redis.hset(key_name,name,val)
        instance_variable_set(instance_var,val)

        if @@sorts.member? name.to_sym
          # score = val.is_a?(String) ? EasyRedis.string_score(val) : val
          EasyRedis.redis.zadd(sort_prefix(name),EasyRedis.score(val),@id)
        end
      end
    end

    # index a field to be sorted/searched
    def self.sort_on(field)
      @@sorts ||= []
      @@sorts << field.to_sym
    end

    # returns number of instances of this model
    def self.count
      EasyRedis.redis.zcard(prefix.pluralize)
    end

    # get all instances of this model
    # ordered by creation time
    def self.all(options = {:order => :asc})
      #ids = []
      #if options[:order] == :asc
      #  ids = EasyRedis.redis.zrange(prefix.pluralize,0,-1)
      #elsif options[:order] == :desc
      #  ids = EasyRedis.redis.zrevrange(prefix.pluralize,0,-1)
      #else
      #  raise EasyRedis::UnknownOrderOption, options[:order]
      #end
      #ids.map{|i| new(i) }
      self.sort_by :created_at, options
    end

    # find an instance of this model based on its id
    def self.find(id)
      if EasyRedis.redis.zscore(prefix.pluralize,id)
        new(id)
      else
        nil
      end
    end

    # alias for find
    def self.[](id)
      find(id)
    end

    # get all instances where the given field matches the given value
    def self.search_by(field_name, val, options = {})
      raise EasyRedis::FieldNotSortable, field_name unless @@sorts.member? field_name.to_sym
      scr = EasyRedis.score(val)
      # options[:limit] = [0,options[:limit]] if options[:limit]
      ids = EasyRedis.redis.zrangebyscore(sort_prefix(field_name),scr,scr,proc_options(options))
      ids.map{|i| new(i) }
    end
    
    # get the first instance where the given field matches val
    def self.find_by(field_name,val)
      search_by(field_name,val,:limit => 1).first
    end

    # get all the entries, sorted by the given field
    def self.sort_by(field,options = {:order => :asc})
      EasyRedis::Sort.new(field,options[:order],self)
    end

    # gives all values for the given field that begins with str
    def self.matches(field,str)
      scr = EasyRedis.score(str)
      a,b = scr, scr+1/(27.0**str.size)
      ids = EasyRedis.redis.zrangebyscore(sort_prefix(field), "#{a}", "(#{b}")
      s = Set.new  
      ids.each{|i| s << new(i).send(field.to_s) }
      s.to_a
    end

    # searches for all entries where the given field begins with the given string
    #
    # should only be called on string fields
    def self.match(field,str, options = {})
      raise EasyRedis::FieldNotSortable, filename unless @@sorts.member? field
      scr = EasyRedis.score(str)
      a,b = scr, scr+1/(27.0**str.size)
      ids = EasyRedis.redis.zrangebyscore(sort_prefix(field), "#{a}", "(#{b}", proc_options(options))
      ids.map{|i| new(i)}
    end

    def self.sortable?(field)
      @@sorts.member? field
    end

    # destroy all instances of this model
    def self.destroy_all
      all.each {|x| x.destroy}
      @@sorts.each {|field| EasyRedis.redis.del(sort_prefix(field)) }
      EasyRedis.redis.del(prefix.pluralize)
      EasyRedis.redis.del(prefix + ":next_id")
    end


    # the id of this entry
    attr_reader :id

    def initialize(id=nil)
      if id
        @id = id
      else
        @id = EasyRedis.redis.incr(prefix + ':next_id')
        EasyRedis.redis.zadd(prefix.pluralize,Time.now.to_i,@id)
        @id
      end
    end

    # get the creation time of an entry
    def created_at
      Time.at(EasyRedis.redis.zscore(prefix.pluralize,@id).to_i)
    end

    # directly access a field
    def [](field)
      EasyRedis.redis.hget(key_name,field)
    end
    
    # directly change a field's value
    def []=(field,val)
      if val
        EasyRedis.redis.hset(key_name,field,val)
      else
        EasyRedis.redis.hdel(key_name,field)
      end
    end

    # remove the entry
    def destroy
      EasyRedis.redis.zrem(prefix.pluralize,@id)
      EasyRedis.redis.del(key_name)
    end

    def inspect
      "#<#{self.class.name}:#{@id}>"
    end


    private 

    def self.get_temp_key
      i = EasyRedis.redis.incr prefix.pluralize + ':next_tmp_id'
      "#{name}:tmp_#{i}"
    end

    def self.proc_options(options)
      opts = {}
      opts[:limit] = [0,options[:limit]] if options[:limit]
      opts
    end

    def self.prefix
      self.name.downcase
    end

    def self.sort_prefix(field)
      if field == :created_at
        prefix.pluralize
      else
        prefix.pluralize + ':sort_' + field.to_s
      end
    end

    def prefix
      self.class.prefix
    end

    def sort_prefix(field)
      self.class.sort_prefix(field)
    end

    def key_name
      prefix + ':' + @id.to_s
    end
  end
end
