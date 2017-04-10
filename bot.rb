require 'facebook/messenger'
require 'connection_pool'
include Facebook::Messenger
# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Ohm.redis =
  Redic.new ENV['REDISTOGO_URL']
#ConnectionPool.new(size: 5, timeout: 5) do
#  Redic.new ENV['REDISTOGO_URL']
#end

Bot.on :message do |message|
  puts "Received '#{message.inspect}' from #{message.sender}"
  case message.text.downcase
    when /^ci sono/
      parse_days(message)
    when /lista/
      print_lista(message)
    when /^non ci sono mai/
      parse_days(message)
    when /^aiuto/
      say_help(message)
    else

  end
end

def print_lista(message)
  days={luned: 0,marted: 0,mercoled: 0,gioved: 0, venerd: 0}
  list = List.find(recipient: recipient(message)).first
  week = JSON.parse list.days
  week.each_value do |u|
    u.select{|k,v| v > 0}.each do |k,v|
      days[k.to_sym] =+ 1
    end
  end
  ret = "Ci sono"
  days.select{|k,v| v > 0}.sort_by{|e| e.last}.reverse.each do |d|
    ret << " #{d.last} person#{d.last==1?'a':'e'} il #{d.first}i,"
  end
  ret.chop!
  message.reply text: ret
rescue Exception => e
  puts e.inspect
  5.times do |n|
    puts e.backtrace[n]
  end
  message.reply text: 'mmmmmmmmmmh'
end

def parse_days(message)
  days={luned: 0,marted: 0,mercoled: 0,gioved: 0, venerd: 0}
  reply= "Ok, "
  days.each_key do |day|
    days[day] = 1 unless message.text.downcase.index(day.to_s).nil?
  end
  days.select{|k,v| v != 0}.each_key{|day| reply << "#{day.to_s}i " }

  save_on_redis(message, days)
  message.reply(text: reply)
end

def save_on_redis(message, days)
  puts message.inspect
  puts days.inspect

  list = List.create(recipient: recipient(message), created_at: Time.now.to_s) rescue List.find(recipient: recipient(message)).first

  list.checktime

  puts "list: #{list.inspect}"

  week = JSON.parse( list.days ) rescue {}
  week[sender(message)] = days
  puts week.inspect
  puts week.to_json
  list.update days: week.to_json
  #list.save
rescue Exception => e
  puts e.inspect
  5.times do |n|
    puts e.backtrace[n]
  end
  message.reply text: 'mmmmmmmmmmh'
end

def say_help(message)
  ret = "Dimmi 'ci sono' ed i giorni della settimana in cui ci saresti per giocare,
ad esempio:
  'Ci sono martedi e giovedi'

Dimmi 'lista' e ti dico quante persone ci sono nei vari giorni.

Chiedimi 'aiuto' ed io ti do una mano
  "

  message.reply text: ret
end

def recipient(message)
  message.recipient['id']
end

def sender(message)
  message.sender['id']
end
