require 'rubygems'
require 'bundler'

Bundler.require

REDIS = EventMachine::Synchrony::ConnectionPool.new(:size => 5) do
  Redis.connect
end

class Redirect < Goliath::API
  use Goliath::Rack::Params
  def response(env)
    url = REDIS.get params[:key]
    if url
      [302, {:location => url}, nil]
    else
      [404, {}, 'Not Found']
    end
  end
end

class Create < Goliath::API
  use Goliath::Rack::Params
  def response(env)
    if params['url']
      key = REDIS.keys.size.base62_encode
      REDIS.set(key, params['url'])
      [200, {}, "http://#{env['HTTP_HOST']}/#{key}"]
    else
      [200, {}, "Hi!"]
    end
  end
end

class Shortener < Goliath::API
  map "/" do
    run Create.new
  end

  map "/:key" do
    run Redirect.new
  end
end