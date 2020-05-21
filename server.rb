#!/usr/bin/ruby

require 'sinatra'
require 'json'

class ConnManager
  attr_reader :connections

  def initialize
    @connections = []
  end

  def purge
    connections.reject!(&:closed?)
  end

  def each(&block)
    connections.each(&block)
  end

  def broadcast(message)
    message = message.to_json unless message.is_a? String
    purge
    each do |out|
      out << "data: #{message}\n\n"
    end
  end

  def <<(conn)
    connections << conn
  end

end

class Message
  attr_accessor :type, :params

  def initialize(type, **kwargs)
    @type = type
    @params = kwargs
  end

  def to_json
    hash = params.dup
    hash[:type] = type
    hash.to_json
  end

end

FirstWord = %w[Deterministic Commutative Associative Monoidal Symmetric Categorical
          Admissable Consistent Tautological Monadic Functorial Linear Quadratic Polynomial]
SecondWord = %w[Aardvark Penguin Dolphin Sprite Goose Duck Lion Tiger Goat Coyote Armadillo
           Canary Dove Eagle Pigeon]

def generate_nick
  "#{FirstWord.sample} #{SecondWord.sample}"
end

set :server, :thin

manager = ConnManager.new

get '/' do
  erb :index
end

get '/subscribe' do
  status 200
  content_type 'text/event-stream'
  stream(:keep_open) { |out| manager << out }
end

get '/request_nick' do
  status 200
  content_type 'application/json'
  { 'nickname': generate_nick }.to_json
end

get '/join' do
  nickname = params['nickname']
  return [400, { 'Content-Type': 'text/plain' }, 'please supply a nickname'] unless nickname
  manager.broadcast Message.new('join', nickname: nickname)
  [200, { 'Content-Type': 'text/plain' }, 'okay']
end

post '/depart' do
  begin
    request.body.rewind
    body = JSON.parse(request.body.read)
  rescue JSON::ParserError
    [400, { 'Content-Type': 'text/plain' }, "JSON Parse Error"]
  else
    nickname = body['nickname']
    return [400, { 'Content-Type': 'text/plain' }, 'please supply a nickname'] unless nickname
    manager.broadcast Message.new('depart', nickname: nickname)
    [200, { 'Content-Type': 'text/plain' }, 'okay']
  end
end

get '/change_nick' do
  old = params['old']
  new = params['new']
  return [400, { 'Content-Type': 'text/plain' }, 'bad arguments'] unless old and new
  manager.broadcast Message.new('change_nick', old: old, new: new)
  [200, { 'Content-Type': 'text/plain' }, 'okay']
end

post '/send' do
  begin
    request.body.rewind
    body = JSON.parse(request.body.read)
  rescue JSON::ParserError
    [400, { 'Content-Type': 'text/plain' }, "JSON Parse Error"]
  else
    sender = body['sender']
    contents = body['contents']
    return [400, { 'Content-Type': 'text/plain' }, 'bad arguments'] unless sender and contents
    manager.broadcast Message.new('message', sender: sender, contents: contents)
    [200, { 'Content-Type': 'text/plain' }, 'okay']
  end
end
