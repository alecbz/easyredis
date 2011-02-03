require 'redis'
require 'active_support/inflector'

module EasyRedis
  
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

  def self.redis
    @redis
  end

  def self.connect(options = {})
    @redis = Redis.new(options)
  end

  class Model

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
          score = val.is_a?(String) ? EasyRedis.string_score(val) : val
          EasyRedis.redis.zadd(prefix.pluralize + ':sort_' + name,score,@id)
        end
      end
    end

    def self.sort_on(field)
      @@sorts ||= []
      @@sorts << field.to_sym
    end

    def self.all(options = {:order => :asc})
      ids = []
      if options[:order] == :asc
        ids = EasyRedis.redis.zrange(prefix.pluralize,0,-1)
      elsif options[:order] == :desc
        ids = EasyRedis.redis.zrevrange(prefix.pluralize,0,-1)
      else
        raise "order option not recognized"
      end
      ids.map{|i| new(i) }
    end

    def self.find(id)
      if EasyRedis.redis.zscore(prefix.pluralize,id)
        new(id)
      else
        nil
      end
    end

    def self.[](id)
      find(id)
    end

    def self.sort_by(field_name,options = {:order => :asc})
      if @@sorts.member? field_name
        ids = []
        if options[:order] == :asc
          ids = EasyRedis.redis.zrange(prefix.pluralize + ':sort_' + field_name.to_s,0,-1)
        elsif options[:order] == :desc
          ids = EasyRedis.redis.zrevrange(prefix.pluralize + ':sort_' + field_name.to_s,0,-1)
        else
          raise "order option not recognized"
        end
        ids.map{|i|new(i)}
      end
    end

    def self.prefix
      self.name.downcase
    end

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

    def created_at
      Time.at(EasyRedis.redis.zscore(prefix.pluralize,@id).to_i)
    end

    def [](field)
      EasyRedis.redis.hget(key_name,field)
    end

    def []=(field,val)
      if val
        EasyRedis.redis.hset(key_name,field,val)
      else
        EasyRedis.redis.hdel(key_name,field)
      end
    end

    #    private 

    def prefix
      self.class.prefix
    end

    def key_name
      prefix + ':' + @id.to_s
    end
  end
end
