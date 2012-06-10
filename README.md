CHORE
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

This will start a server that listens on port XXXX.

To view status from the command line:

    blah

To view status from a web-server:

    http://localhost:8889

