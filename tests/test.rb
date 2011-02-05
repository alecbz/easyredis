require './lib/easyredis'

class Man < EasyRedis::Model
  field :name
  field :friend

  sort_on :name
end

EasyRedis.connect
