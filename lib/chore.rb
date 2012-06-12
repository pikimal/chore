require 'socket'
require 'json'
require 'chore/constants'

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
  @@server_port = Chore::Constants::DEFAULT_LISTEN_PORT

  def self.send msg
    UDPSocket.new.send(sanitize(msg).to_s, 0, @@server_ip, @@server_port)
    nil
  end

  #only allow good options
  def self.sanitize msg
    msg.to_json
  end

  def self.set_server ip, port
    @@server_ip = ip
    @@server_port = port
  end
  
  def self.start task, opts={}
    opts[:start_time] = Time.now().to_i
    send( [:start, task, opts] )
  end

  def self.status task, message
    send( [:status_update, task, { :status_note => message}] )
  end

  def self.finish task, opts={}
    opts[:finish_time] = Time.now().to_i
    send( [:finish, task, opts] )
  end
  
  def self.pop task, opts={}
    send( [:pop, task, opts] )
  end

  # :error => message
  def self.fail task, opts={}
    opts[:fail_time] = Time.now().to_i
    send( [:fail, task, opts] )
  end
  
  # In addition to normal opts, :pop => true
  # will automatically remove the task from the store
  def self.monitor task, opts={}, &code
    pop = false
    if opts[:pop]
      pop = true
      opts.delete(:pop)
    end
    
    Chore.start(task, opts)
    begin
      code.call()
      Chore.finish(task)
      Chore.pop(task) if pop
    rescue Exception => ex
      Chore.fail(task, :error => "#{ex.class} - #{ex.message}")
      raise
    end
  end
  

end
