require './lib/easyredis'

class Man < EasyRedis::Model
  field :name
  field :age

  sort_on :name
  sort_on :age
end

EasyRedis.connect
