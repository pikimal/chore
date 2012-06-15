require 'socket'
require 'json'
require 'chore/constants'

# Client module to access the server.  Basic usage is something like:
# 
#    Chore.monitor('task') do
#      # ...
#    end
# 
# Refer to the various methods for additional options
module Chore

  # Override the default server settings
  def self.set_server ip, port
    @@server_ip = ip
    @@server_port = port
  end
  
  # Let the server know that you've started a task.
  # Options you can include are:
  #
  # [:do_every]     Indicate that the task should run every X seconds.
  #                 If this does not happen, show task status in RED.
  #
  # [:grace_period] Allow a grace period for the above option.  If we
  #                 are late but withing the grace period, show task
  #                 status in YELLOW.
  #
  # [:finish_in]    Indicate that the task should finish in X seconds.
  #                 If we haven't received a finish message by then,
  #                 show the task in RED.
  #
  # [:expire_in]    Remove the task after X seconds.  This may be useful
  #                 to keep the task list clean.
  def self.start task, opts={}
    opts[:start_time] ||= Time.now().to_i
    send( [:start, task, opts] )
  end

  # Provide an optional status message that can be updated.
  # Only the last status message is retained.
  def self.status task, message
    send( [:status_update, task, { :status_note => message}] )
  end

  # Manually indicate that a task has finished
  def self.finish task, opts={}
    opts[:finish_time] ||= Time.now().to_i
    send( [:finish, task, opts] )
  end
  
  # Remove a task from monitoring.
  def self.pop task, opts={}
    send( [:pop, task, opts] )
  end

  # Manually indicate that a task has failed.
  #
  # [:error] optional error message
  def self.fail task, opts={}
    opts[:fail_time] ||= Time.now().to_i
    send( [:fail, task, opts] )
  end
  
  # Automatically run Chore.start, execute a code block, and
  # automatically run Chore.finish (or Chore.fail in the case
  # of an exception) when the block finishes.
  #
  # All options from .start, .finish, and .fail may be passed
  # in as options.
  #
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
      if pop
        Chore.pop(task)
      else
        Chore.finish(task)
      end
    rescue Exception => ex
      Chore.fail(task, :error => "#{ex.class} - #{ex.message}")
      raise
    end
  end

private
  
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
end
