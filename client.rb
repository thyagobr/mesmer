require 'socket'
require 'colorize'

@server = TCPSocket.new 'irc.freenode.org',6667 

def send_to_server(msg)
  puts "#>> #{msg}"
  @server.puts msg
end

def extract_nickname(user_info)
  return user_info.split("!")[0].to_s[1..-1]
end

send_to_server "NICK thenickless"
send_to_server "USER nothingness 8 * :whatness"

def handle_incoming_message(message)
  message = message.split 
  if (message[0] =~ /^PING(.*)$/)
    send_to_server "PONG #{$~[1]}"
  elsif (message[1] == "353")
    @names = "" if not @names
    @names << message[5..-1].join(' ').gsub(':', '')
  elsif (message[1] == "366")
    puts "online: ".red + @names.blue
    @names = nil
  elsif (message[1] == "PRIVMSG") and (message[2][0] == "#")
    print "#{extract_nickname(message[0])}".magenta + " to ".blue + "#{message[2]}".white + ": #{message[3..-1].join(' ')}\r\n"
  else
    print "#{message[0]} ".magenta + message[1..-1].join(' ') + "\r\n"
  end
end

thr1 = Thread.new do
  while line = @server.gets # Read lines from socket
    handle_incoming_message(line)
  end
end

thr2 = Thread.new do
  while input = $stdin.gets.chomp
    @server.puts(input)
  end
end

[thr1, thr2].each { |t| t.join }

at_exit do
  [thr1, thr2].each { |t| t.exit }
  @server.close             # close socket when done
end

