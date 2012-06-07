require 'socket'

#
# Usage:
# 
# Chore.start(:reset_percentages, :do_every => 15.minutes, :finish_in => 20.minutes, :grace_period => 30.minutes)
#
# Chore.finish(:reset_percentages)
# 
# finish is optional and only used if start includes :finish_in
module Chore

  @@server_ip = '127.0.0.1'
  @@server_port = 7779

  def self.send msg
    UDPSocket.new.send(sanitize(msg).to_s, 0, @@server_ip, @@server_port)
  end

  #only allow good options

  def self.sanitize msg
    msg
  end

  def self.set_server ip, port
    @@server_ip = ip
    @@server_port = port
  end
  

  def self.start task, opts={}
    opts[:start_time] = Time.now().to_i
    send( [:start, task, opts] )
  end

  def self.finish task, opts={}
    opts[:finish_time] = Time.now().to_i
    send( [:finish, task, opts] )
  end
  
  # :error => message
  def self.fail task, opts={}
    opts[:fail_time] = Time.now().to_i
    send( [:fail, task, opts] )
  end
  
end

Chore.start(:crazy_background_task, :do_every => 60, :grace_period => 2400)
Chore.start(:random_resque_job, :do_every => 1200)
Chore.start(:custom_script, :do_every => 2400)
Chore.start(:logrotate, :do_every => 1)

Chore.start(:exceptional)
Chore.fail(:exceptional, :error => "Another freaking nil error")

Chore.start(:exceptionally_anonymous)
Chore.fail(:exceptionally_anonymous)

Chore.start(:finish_anytime)
Chore.finish(:finish_anytime)

Chore.start(:slow, :finish_in => 20000000)
Chore.finish(:slow)

Chore.start(:quick, :finish_in => 1)
sleep(5)
Chore.finish(:quick)
