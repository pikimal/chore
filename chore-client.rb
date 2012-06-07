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

  def self.send msg
    UDPSocket.new.send(sanitize(msg).to_s, 0, '127.0.0.1', 7779)
  end

  #only allow good options

  def self.sanitize msg
    msg
  end

  def self.start task, opts={}
    opts[:run_time] = Time.now().to_i
    send( [:start, task, opts] )
  end

  def self.finish
    opts[:run_time] = Time.now().to_i
    send( [:finish, task, opts] )
  end
  
  def self.fail
    opts[:run_time] = Time.now().to_i
    send( [:fail, task, opts] )
  end
  
end

Chore.start(:crazy_background_task, :do_every => 60, :grace_period => 2400)
Chore.start(:random_resque_job, :do_every => 1200)
Chore.start(:custom_script, :do_every => 2400)
Chore.start(:logrotate, :do_every => 1)
