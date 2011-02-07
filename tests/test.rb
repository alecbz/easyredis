require './lib/easyredis'

class Man < EasyRedis::Model
  field :name
  field :age

  text_search :name
  sort_on :age
end

EasyRedis.connect
