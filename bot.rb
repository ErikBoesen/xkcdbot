require "sinatra"
require "mebots"
require "json"
require "net/http"

PREFIX = "xkcd"
bot = Bot.new("xkcdbot", ENV["BOT_TOKEN"])

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

get "/" do
  "I'm XKCDBot!"
end

post "/" do
  message = JSON.parse(request.body.read)
  responses = process(message)
  puts responses
end
