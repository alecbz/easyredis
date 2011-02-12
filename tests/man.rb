require './lib/easyredis'

class Man < EasyRedis::Model
  field :name
  field :age

  search_on :name
  search_on :age
end

EasyRedis.connect
