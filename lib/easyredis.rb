# EasyRedis is a simple ruby framework designed to make using Redis as a database simpler.
#
# Redis is a very fast key-value store that supports data structures like lists, (sorted) sets, and hashes, but because of its simplicity, using Redis to store traditional database data can be somewhat tedious. EasyRedis streamlines this process.
#
# Author:: Alec Benzer (mailto:alecbenzer@gmail.com)


require 'redis'
require 'set'


# main EasyRedis module which
# holds all classes and helper methods
module EasyRedis
  
  # generate a 'score' for a string
  # used for storing it in a sorted set
  #
  # This method effectively turns a string into a base 27 floating point number,
  # where 0 corresponds to no letter, 1 to A, 2 to B, etc.
  #
  # @param [String] str the string we are computing a score for
  # @return [Number] the string's score
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
  # The score is determined as follows:
  # First, if the object is a string, {string_score} is used to get its score.
  # Otherwise, we try calling the following methods on the object in turn, returning the first that works: score, to_f, to_i.
  # If none of those work, we simply return the object itself.
  #
  # @param obj the object to retrive a score for
  # @return [Number] the object's score
  def self.score(obj)
    if obj.is_a? String
      string_score(obj)
    elsif obj.respond_to? "score"
      obj.score
    elsif obj.respond_to? "to_f"
      obj.to_f
    elsif obj.respond_to? "to_i"
      obj.to_i
    else
      obj
    end
  end

  # access the redis object
  # @return [Redis]
  def self.redis
    @redis
  end

  # connect to a redis server
  #
  # takes the same options that Redis#new does from the redis gem
  #
  # @param [Hash] options a hash of options to feed to Redis.new
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

  # exception that indicates that the given field has not been indexed for text-searching
  class FieldNotTextSearchable < RuntimeError
    def initialize(field)
      @message = "field '#{field.to_s}' not text-searchable"
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

  # class representing a generic collection
  class Collection
    include Enumerable

    # access elements in this sort
    #
    # Work's like an Array's [] method. It can take a specific index, a range, or an offset and an amount/limit.
    # This method uses the underlying access method, which handles the actual retrival.
    #
    # @param [Range, Number] index either a number corresponding to a specific element,
    #   a range corresponding to a range of elements,
    #   or a number indicating an offset, if limit is also specified
    #
    # @param [Number] limit index is interpreted as an offset and limit is the number of elements to return from that offset
    def [](index,limit=nil)
      if limit
        offset = index
        self[offset...(offset+limit)]
      elsif index.is_a? Range
        access(index)
      elsif index.is_a? Integer
        self[index..index].first
      end
    end

    # iterate through all members of this collection
    def each
      self[0..-1].each { |o| yield o }
    end

    # return the fist element of this collection, or the first n elements, if n is given
    def first(n = nil)
      if n
        self[0,n]
      else
        self[0]
      end
    end

    # return the last element of this collection, or the last n elements, if n is given
    def last(n = nil)
      if n
        self[-n..-1]
      else
        self[-1]
      end
    end

    private

    # access the elements corresponding to the given range
    #
    # meant to be overridden in child classes
    def access(range)
      []
    end

  end

  # class representing a sort
  class Sort < Collection

    # initialize the sort with a specific field, ordering option, and model
    #
    # @param [Symbol] field a symbol corresponding to a field of klass
    # @param [:asc, :desc] order a symbol specifying to sort in either ascending or descending order
    # @param [Class] klass the klass whose entries we are accessing
    def initialize(field,order,klass)
      raise EasyRedis::FieldNotSortable, field  unless klass.sortable?(field) 
      raise EasyRedis::UnknownOrderOption, order  unless [:asc,:desc].member? order
      @field = field
      @order = order
      @klass = klass
    end

    # return the number of elements in this sort
    #
    # As of now, idential to the Model's count method.
    # This method is explicility defined here to overwrite the default one in Enumerable, which iterates through all the entries to count them, which is much slower than a ZCARD command
    def count
      @count ||= EasyRedis.redis.zcard(@klass.sort_key(@field))
      @count
    end

    def inspect
      "#<EasyRedis::Sort model=#{@klass.name}, field=#{@field.to_s}, order=#{@order.to_s}>"
    end

    private

    # takes a range and returns corresponding elements
    def access(range)
      a = range.begin
      b = range.end
      b -= 1 if range.exclude_end?
      ids = []
      if @order == :asc
        ids = EasyRedis.redis.zrange(@klass.sort_key(@field),a,b)
      elsif @order == :desc
        ids = EasyRedis.redis.zrevrange(@klass.sort_key(@field),a,b)
      end
      ids.map{|i|@klass.build(i)}
    end

  end


  # class representing a data model
  # you want to store in redis
  class Model
    
    @@sorts = []
    @@text_searches = []

    # add a field to the model
    #
    # @param [Symbol] name a symbol representing the name of the field
    def self.field(name)
      @@fields ||= []
      @@fields << name.to_sym
      name = name.to_s
      getter = name
      setter = name + "="
      instance_var = '@' + name

      define_method getter.to_sym do
        prev = instance_variable_get(instance_var)
        if prev
          prev
        else
          instance_variable_set(instance_var,Marshal.load(EasyRedis.redis.hget(key_name,name)))
        end
      end

      define_method setter.to_sym do |val|
        EasyRedis.redis.hset(key_name,name,Marshal.dump(val))
        instance_variable_set(instance_var,val)

        if self.class.sortable? name.to_sym
          EasyRedis.redis.zadd(sort_key(name),EasyRedis.score(val),@id)
        end

        if self.class.text_search? name.to_sym
          val.split.each do |term|
            EasyRedis.redis.zadd term_key(name,term), created_at.to_i, id
            EasyRedis.redis.zadd terms_key(name), EasyRedis.score(term), term
          end
        end
      end
    end

    # index a field to be sorted/searched
    #
    # @param (see #field)
    def self.sort_on(field)
      @@sorts << field.to_sym
    end

    # index a field for text searching
    #
    # @param (see #field)
    def self.text_search(field)
      @@text_searches << field.to_sym
      sort_on(field) unless sortable? field
    end

    # returns number of instances of this model
    def self.count
      EasyRedis.redis.zcard(prefix)
    end

    # get all instances of this model
    # ordered by creation time
    def self.all(options = {:order => :asc})
      self.sort_by :created_at, options
    end

    # same as calling self.all.first
    def self.first(n = nil)
      self.all.first(n)
    end

    # same as calling self.all.last
    def self.last(n = nil)
      self.all.last(n)
    end

    # returns a random entry of this model
    def self.rand
      self[Kernel.rand(self.count)]
    end

    # find an entry of this model based on its id
    #
    # @param [Integer] id the id of the entry to retrive
    def self.find(id)
      if EasyRedis.redis.zscore(prefix,id)
        build(id)
      else
        nil
      end
    end

    # access entries of this model based on time
    # 
    # same as calling self.all.[]
    def self.[](index,amt=nil)
      self.all[index,amt]
    end

    # get all entries where field matches val
    #
    # @param [Symbol] field a symbol representing the field to search on
    # @param val the value of field to search for
    def self.search_by(field, val, options = {})
      raise EasyRedis::FieldNotSortable, field unless @@sorts.member? field.to_sym
      scr = EasyRedis.score(val)
      # options[:limit] = [0,options[:limit]] if options[:limit]
      ids = EasyRedis.redis.zrangebyscore(sort_key(field),scr,scr,proc_options(options))
      ids.map{|i| build(i) }
    end

    # get the first entry where field matches val
    #
    # @param (see #search_by)
    def self.find_by(field,val)
      search_by(field,val,:limit => 1).first
    end

    # search the model based on multiple parameters
    #
    # @param [Hash] params a hash of field => value pairs
    def self.search(params)
      return search_by(*params.first) if params.size == 1  # comment out for benchmarking purposes
      result_set = nil
      params.each do |field,value|
        scr = EasyRedis.score(value)
        ids = EasyRedis.redis.zrangebyscore(sort_key(field),scr,scr)
        result_set = result_set ? (result_set & Set.new(ids)) : Set.new(ids)
      end
      result_set.map{|i|build(i)}
    end

    # get all entries, sorted by the given field
    def self.sort_by(field,options = {:order => :asc})
      EasyRedis::Sort.new(field,options[:order],self)
    end

    # gives all values for the given field that begin with str
    #
    # @param [Symbol] field a symbol representing a field indexed with text_search.
    def self.matches(field,str)
      raise FieldNotTextSearchable, field unless self.text_search? field
      scr = EasyRedis.score(str)
      a,b = scr, scr+1/(27.0**str.size)
      EasyRedis.redis.zrangebyscore(terms_key(field), "#{a}", "(#{b}")
    end

    # searches for all entries where field contains the string str
    #
    # The string must appear exactly as a term in field's value. To search based on the beginning of a term, you can combine this method with matches.
    # The field must have been indexed with text_search.
    def self.match(field,str, options = {})
      raise EasyRedis::FieldNotTextSearchable, filename unless text_search? field
      ids = EasyRedis.redis.zrange(term_key(field,str), 0, -1, proc_options(options))
      ids.map{|i| build(i)}
    end

    # indicates whether field has been indexed with sort_on
    def self.sortable?(field)
      @@sorts and (@@sorts.member? field or field.to_sym == :created_at)
    end

    # indicates whether field has been indexed with text_search
    def self.text_search?(field)
      @@text_searches and @@text_searches.member?(field)
    end

    # destroy all instances of this model
    def self.destroy_all
      all.each {|x| x.destroy}
      @@sorts.each {|field| EasyRedis.redis.del(sort_key(field)) }
      @@text_searches.each {|field| EasyRedis.redis.del(terms_key(field)) }
      EasyRedis.redis.del(prefix)
      EasyRedis.redis.del(prefix + ":next_id")
    end
    

    # the id of this entry
    attr_reader :id

    # create a new instance of this model
    #
    # @param [String] id optional id to use for the entry
    #   if you leave this parameter out an id will be generated for you
    # @param [Boolean] check this flag is used for internal purposes.
    #   LEAVE IT AS TRUE
    def initialize(id=nil,check=true)
      if id
        @id = id.to_s
        if check
          raise "id #{id} is already in use" if EasyRedis.redis.zscore(prefix,id)
          EasyRedis.redis.zadd(prefix,Time.now.to_i,@id)
        end
      else
        @id = EasyRedis.redis.incr(prefix + ':next_id').to_s
        EasyRedis.redis.zadd(prefix,Time.now.to_i,@id)
      end
    end

    # get the creation time of an entry
    def created_at
      Time.at(EasyRedis.redis.zscore(prefix,@id).to_i)
    end

    # directly access a field of this entry's redis hash
    #
    # note that you cannot access created_at or id with these methods
    def [](field)
      EasyRedis.redis.hget(key_name,field)
    end

    # directly change a field of this entry's redis hash
    #
    # note that you cannot access created_at or id with these methods
    def []=(field,val)
      if val
        EasyRedis.redis.hset(key_name,field,val)
      else
        EasyRedis.redis.hdel(key_name,field)
      end
    end

    # remove the entry
    def destroy
      EasyRedis.redis.zrem(prefix,@id)
      EasyRedis.redis.del(key_name)
    end

    # returns the key name of this entry's redis hash  
    def key_name
      "#{prefix}:#{@id}"
    end

    def inspect
      "#<#{self.class.name}:#{@id}>"
    end

    # clears all fields, causing future gets to reretrive them from redis
    def clear
      @@fields.each do |field|
        self.instance_variable_set("@"+field.to_s,nil)
      end
    end


    private 

    def self.build(id)
      new(id,false)
    end

    # generate a temporary key name associated with this model
    def self.get_temp_key
      i = EasyRedis.redis.incr "#{prefix}:next_tmp_id"
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

    def self.sort_key(field)
      if field == :created_at
        prefix
      else
        "#{prefix}:sort_#{field.to_s}"
      end
    end

    def self.terms_key(field)
      "#{prefix}:terms_#{field.to_s}"
    end

    def self.term_key(field,term)
      "#{prefix}:term_#{field}:#{term}"
    end

    def prefix
      self.class.prefix
    end

    def sort_key(field)
      self.class.sort_key(field)
    end

    def terms_key(field)
      self.class.terms_key(field)
    end

    def term_key(field,term)
      self.class.term_key(field,term)
    end
  end
end
