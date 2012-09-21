require 'eventmachine'
require 'chore/time_help'

module Chore
  # A semi-persistant store for all of our chore data.  Right now
  # it's just a hash that won't survive a server restart.
  module Store
    #
    # Process data with a spawned process in the background 
    #

    def self.update_chore chore_info
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

    # Remove anything that's currently expired from the store.
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

    # get status of a single chore
    def self.get_chore chore_name
      chore_name = chore_name.to_s
      chore_data = Store.get[chore_name]

      return nil if chore_data.nil?
      
      build_status(chore_name, chore_data)
    end

    # Climb through the internal store and return a processed and
    # abstracted list of tasks to the consumer.
    def self.iterate_statuses
      ret = []
      Store.get.keys.each do |chore_name|
        yield get_chore(chore_name)
      end
    end

  private
    @@store = {}

    def self.get
      @@store
    end

    def self.build_status chore_name, status_info
        status = status_info['status'].to_sym
        run_time = status_info['start_time']
        run_time = 0 if !run_time

        current_time = Time.now.to_i
        do_every = status_info['do_every']
        grace_period = status_info['grace_period']

        notes = []
        state = :red

        if status == :fail
          state = :red
          if status_info['error']
            notes << status_info['error']
          else
            notes << "FAILED!!!"
          end
          
        elsif status == :finish
          finish_time = status_info['finish_time']
          finish_in = status_info['finish_in']

          if finish_in.nil?
            state = :green
          elsif (run_time + finish_in) >= finish_time
            state = :green
          else
            state = :red
            notes << "Finished, but #{finish_time - (run_time + finish_in)} seconds late!!!"
          end
        elsif status == :start || status == :status_update
          state = :green

          if status_info['expire_in']
            expire_in = Time.at(status_info['start_time'] + status_info['expire_in'].to_i)
            notes << "Will expire in #{expire_in}"
          end

          notes << "Status: #{status_info['status_note']}" if status_info['status_note']
        end

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
        
        info = {:job => chore_name, :state => state, :status => status, :start_time => run_time, :notes => notes}
    end


  end
end
