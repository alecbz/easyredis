require './lib/easyredis'

class Man < EasyRedis::Model
  field :name
  sort_on :name
end

EasyRedis.connect
