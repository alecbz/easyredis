require './lib/easy_redis'

class Man < EasyRedis::Model
  field :name
  sort_on :name
end

EasyRedis.connect
