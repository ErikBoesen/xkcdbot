require "sinatra"
require "mebots"
require "json"
require "net/http"

PREFIX = "xkcd"
BOT = Bot.new("xkcdbot", ENV["BOT_TOKEN"])

def xkcd_get(query)
  uri = URI(query != "" ? "https://xkcd.com/#{query}/info.0.json" : "https://xkcd.com/info.0.json")
  response = Net::HTTP.get(uri)
  return JSON.parse(response)
end

def process(message)
  text = message["text"].downcase
  responses = []
  if message["sender_type"] == "user"
    if text.start_with?(PREFIX)
      text = text.sub(PREFIX, "").strip
      comic = xkcd_get(text)
      responses.push([comic["alt"], comic["img"]])
    end
  end
  return responses
end

def reply(message, group_id)
  if message.kind_of?(Array)
    message.each { |item|
      reply(item, group_id)
    }
  else
    uri = URI("https://api.groupme.com/v3/bots/post")
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    puts group_id
    BOT.instance(group_id)
    puts BOT.instance(group_id).id
    req.body = {
        bot_id: BOT.instance(group_id).id,
        text: message,
    }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end
end

get "/" do
  "I'm XKCDBot!"
end

post "/" do
  message = JSON.parse(request.body.read)
  responses = process(message)
  if responses
    reply(responses, message["group_id"])
  end
end
