Gem::Specification.new do |s|
  s.name = 'chore'
  s.version = '0.0.0'
  s.date = '2012-06-10'
  s.summary = "Monitor chores"
  s.description = "Monitor chorse"
  s.authors = ["Pikimal, LLC"]
  s.homepage = "http://github.com/pikimal/chore"
  s.email = "grant@pikimal.com"
  s.files = ['lib/chore.rb', 'lib/chore/server.rb','lib/chore/time_help.rb', 'lib/chore/store.rb', 'lib/chore/constants.rb']
  s.executables << 'chore-server'
  s.executables << 'chore-status'
  s.executables << 'chore-client'
  s.add_dependency('eventmachine','>= 0.2.10')
  s.add_dependency('eventmachine_httpserver', '>= 0.2.1')
  s.add_dependency('trollop', ">= 1.16.2")
  s.add_development_dependency("rspec")
end