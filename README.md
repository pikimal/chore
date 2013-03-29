Chore
=====

Chore is a system health monitoring tool for everyone.

There are more sophisticated tools, tools with better disaster
recovery, tools that monitor CPU/Swap/Disk-space, to be sure.  But
these usually require switching gears from your main codebase, an
advanced learning curve, and often find themselves used only by a
dedicated systems person or a single resident expert on your team.

Chore provides a simple API that anyone can start using in 5 minutes
or less.  This allows any developer to add their own monitoring to
tasks with little to no effort.

Chore provides a simple ruby interface to indicate:

*   When a task is started.  (Is it actually running?)

*   Optionally when it finished and/or errored.  (Is it completing?)

*   Optionally parameters such as how frequently the job should run
    and/or how long it should take.  (Is it behaving as expected?)

Chore does not:

*   Perform automated recovery of failed tasks.

*   Kill or restart zombie processes.

*   Provide server health info such as high CPU usage, low disk space,
    excessive swapping, etc.

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

# one time config, not needed if server is on localhost
Chore.set_server('hostname',Chore::Constants::DEFAULT_LISTEN_PORT)

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

# Expire an entry in X seconds, whether it's started, finished or
# failed, so that it no longer shows up in output.  Useful when
# attaching an id number or pid to the task name.
Chore.monitor("Cron task with pid #{process_id}", :expire_in => 1.day) {}

```

There is also a command-line tool so you can use the server without
having to fire up irb.

```
johnmudhead:chore grant$ chore-status
test - failed 2012-06-15 17:33:00 -0400 (AAAAAAAAA)
johnmudhead:chore grant$ chore-client --chore test --action pop
johnmudhead:chore grant$ chore-status

johnmudhead:chore grant$ 
```

Verification
------------

This gem is signed with rubygems-openpgp.  You can verify its
integrity by running:

    gem install chore --trust

Much more information on signing is available at the [rubygems-openpgp
Certificate Authority](https://www.rubygems-openpgp-ca.org).


Signing key:

    pub   2048R/E3B5806F 2010-01-11 [expires: 2014-01-03]
          Key fingerprint = A530 C31C D762 0D26 E2BA  C384 B6F6 FFD0 E3B5 806F
    uid                  Grant T. Olson (Personal email) <kgo@grant-olson.net>
    uid                  Grant T Olson <grant@webkite.com>
    uid                  Grant T. Olson (pikimal) <grant@pikimal.com>
    sub   2048R/6A8F7CF6 2010-01-11 [expires: 2014-01-03]
    sub   2048R/A18A54D6 2010-03-01 [expires: 2014-01-03]
    sub   2048R/D53982CE 2010-08-31 [expires: 2014-01-03]
