Gem::Specification.new do |s|
  s.name = 'chore'
  s.version = '0.0.0'
  s.date = '2012-06-10'
  s.summary = "Monitor chores"
  s.description = "Monitor chorse"
  s.authors = ["Grant Olson"]
  s.email = "grant@pikimal.com"
  s.files = ['lib/chore.rb', 'lib/chore/server.rb','lib/chore/time_help.rb', 'lib/chore/store.rb']
  s.executables << 'chore-server'
  s.executables << 'chore-client-test'
end