require 'json'
require 'net/http'

PREFIX = 'xkcd'
POST_URI = URI('https://api.groupme.com/v3/bots/post')
POST_HTTP = Net::HTTP.new(POST_URI.host, POST_URI.port)
POST_HTTP.use_ssl = true
POST_HTTP.verify_mode = OpenSSL::SSL::VERIFY_PEER

def receive(event:, context:)
  message = JSON.parse(event['body'])
  responses = process(message)
  if responses
    reply(responses, message['bot_id'])
  end
  return {
    statusCode: 200,
    body: {
      message: 'Message received'
    }.to_json
  }
end

def xkcd_get(query)
  uri = URI(query != '' ? "https://xkcd.com/#{query}/info.0.json" : 'https://xkcd.com/info.0.json')
  response = Net::HTTP.get(uri)
  return JSON.parse(response)
end

def process(message)
  text = message['text'].downcase
  responses = []
  if message['sender_type'] == 'user'
    if text.start_with?(PREFIX)
      text = text.sub(PREFIX, '').strip
      comic = xkcd_get(text)
      responses.push([comic['alt'], comic['img']])
    end
  end
  return responses
end

def reply(message, bot_id)
  if message.kind_of?(Array)
    message.each { |item|
      reply(item, bot_id)
    }
  else
    req = Net::HTTP::Post.new(POST_URI, 'Content-Type' => 'application/json')
    req.body = {
        bot_id: bot_id,
        text: message,
    }.to_json
    POST_HTTP.request(req)
  end
end
