Chore
=====

Chore is a system health monitoring tool aimed at developers.

It tries to provide a simple centralized interface to monitor all
various 'chores' (regular jobs, asyncronous background jobs, etc) so
you can see if you system is up-to-date.

Basically the problem we were running into was that there we had
health tools, but too many.  Many are configured at the sysops level,
giving useful information about disk space and CPU usage, but this
didn't tell us much about the actual health of our running
application.  Things were AOK according to all the tools, but our data
was actually stale.

Other tools could probably give us the information we need and fix
things automatically, but the learning curve was a bit much for
someone who isn't focused on sysops.

Chore provides a simple ruby interface to indicate:

*   When a job is started.  (Is it actually running?)

*   Optionally when it finished and/or errored.  (Is it completing?)

*   Optionally parameters such as how frequently the job should run
    and/or how long it should take.  (Is it behaving as expected?)

To start a server:

    chore-server

This will start a server.

To view status from the command line:

    chore-status [hostname] [port]

Which will produce output like:

    crazy_background_task - started 2012-06-11 17:11:16 -0400 (Job should run every 1 minute, but has a grace period of 40 minutes)
    random_resque_job - started 2012-06-11 17:11:16 -0400 (Should run every 20 minutes)
    custom_script - started 2012-06-11 17:11:16 -0400 (Should run every 1 hour)
    logrotate - started 2012-06-11 17:11:16 -0400 (Job should run every 1 second, but hasn't run since 2012-06-11 17:11:16 -0400)
    exceptional - failed 2012-06-11 17:11:16 -0400 (Another freaking nil error)
    exceptionally_anonymous - failed 2012-06-11 17:11:16 -0400 (FAILED!!!)
    finish_anytime - finished 2012-06-11 17:11:16 -0400 (no particular deadline)
    slow - finished 2012-06-11 17:11:16 -0400 (Finished)
    quick - finished 2012-06-11 17:11:16 -0400 (Finished, but 4 seconds late!!!)
    good task - finished 2012-06-11 17:11:21 -0400 (no particular deadline)
    bad task - failed 2012-06-11 17:11:21 -0400 (RuntimeError - AAAAAAAAAAAAAAAAAAAAA)

(Todo, how do we show the colors in github)

To view status from a web-server:

    http://localhost:43210

To record a chore in ruby:

```ruby
Chore.monitor(:task_name) do
  # real work
end
```

This will record the start and finish of the wrapped block.

Even simpler, you can just record the start of a task:

```ruby
Chore.start(:task_name)
#do stuff
```

This still requires you to examine timestamps to see if things are
running.  If you want a better visual clue that things are broken, you
can throw in some options.  (All .start options can also be passed
into .monitor)

```ruby
# complain if the task hasn't run in more than an hour.
Chore.start(:task_name, :do_every => 3600)
    
# complain if the task hasn't run in more than an hour, and
# complain more loudly if it hasn't run in two.
Chore.start(:task_name, :do_every => 3600, :grace_period => 3600)
    
# complain if the task hasn't finished in an hour.
Chore.start(:task_name, :finish_in => 3600)
# make sure to call Chore.finish(:task_name) explicitly later, 
# or use Chore.monitor to do so automatically.    

# Record error info for known exception
begin
  Chore.start(:goofy_task)
  raise Errno::ETIMEDOUT # network problems
rescue Errno::ETIMEDOUT => ex
  Chore.fail(:goofy_task, :error => "Crappy router probably needs a reboot."
end

# Add status notes, only the last update shows.
Chore.start(:long_task)
# ...
Chore.status(:long_task, "Downloaded the interwebz")
# ...
Chore.status(:long_task, "Ran bayesian classifier")
# ...

# Remove a task from the store on completion, but not if it fails
Chore.monitor("update widget #{widget.id}", :pop => true) do
  # ...
end

```
