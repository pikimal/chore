require 'eventmachine'
require 'chore/time_help'

module Chore
  # A semi-persistant store for all of our chore data.  Right now
  # it's just a hash that won't survive a server restart.
  module Store
    @@store = {}

    def self.get
      @@store
    end

    #
    # Process data with a spawned process in the background 
    #

    @@data_collector = EM.spawn do |chore_info|
      state = chore_info[0]
      chore = chore_info[1]
      opts = chore_info[2]
      opts['status'] = state
      
      if state == "pop"
        Store.get.delete(chore)
      else
        if Store.get[chore].nil?
          Store.get[chore] = {}
        end

        Store.get[chore] = Store.get[chore].merge(opts)
      end
      
    end

    def self.collect chore_info
      @@data_collector.notify chore_info
    end

    #
    # :section: expire
    #

    # if we have an expiration setting, expire anything thats after
    # the expiration date.
    def self.expire
      expired_tasks = []
      
      Chore::Store.get.each_pair do |task, params|
        if params['expire_in']
          start_time = params['start_time'].to_i
          expire_in = params['expire_in'].to_i
          expire_time = start_time + expire_in
          
          if expire_time < Time.now().to_i
            expired_tasks << task
          end
        end
      end

      expired_tasks.each do |task|
        Chore::Store.get.delete(task)
      end
    end

    #
    # :section: read info
    #
    def self.iterate_statuses
      ret = []
      Store.get.each_pair do |key, val|
        status = val['status'].to_sym
        run_time = val['start_time']
        run_time = 0 if !run_time

        current_time = Time.now.to_i
        do_every = val['do_every']
        grace_period = val['grace_period']

        notes = []
        state = :red

        if status == :fail
          state = :red
          if val['error']
            notes << val['error']
          else
            notes << "FAILED!!!"
          end
          
        elsif status == :finish
          finish_time = val['finish_time']
          finish_in = val['finish_in']

          if finish_in.nil?
            state = :green
          elsif (run_time + finish_in) >= finish_time
            state = :green
          else
            state = :red
            notes << "Finished, but #{finish_time - (run_time + finish_in)} seconds late!!!"
          end
        elsif status == :start || status == :status_update
          if do_every
            if run_time + do_every >= current_time
              state = :green
              notes << "Should run every #{Chore::TimeHelp.elapsed_human_time(do_every)}"
            elsif grace_period && run_time + do_every + grace_period > current_time
              state = :yellow
              notes << "Job should run every #{Chore::TimeHelp.elapsed_human_time(do_every)}, but has a grace period of #{Chore::TimeHelp.elapsed_human_time(grace_period)}"
            else
              state = :red
              notes << "Job should run every #{Chore::TimeHelp.elapsed_human_time(do_every)}, but hasn't run since #{Time.at(run_time)}"
            end
          else
            state = :green
          end

          if val['expire_in']
            expire_in = Time.at(val['start_time'] + val['expire_in'].to_i)
            notes << "Will expire in #{expire_in}"
          end

          notes << "Status: #{val['status_note']}" if val['status_note']
        end
        
        info = {:job => key, :state => state, :status => status, :start_time => run_time, :notes => notes}
        yield info

      end
    end
  end
end
