Gem::Specification.new do |s|
	s.name = "cultome_player"
	s.version = "1.0.0.pre"
	s.date        = '2013-04-15'
	s.summary     = "CulToMe Player"
	s.description = "A ruby console-based music library explorer and player"
	s.authors     = ["Carlos Soria"]
	s.email       = "zooria@gmail.com"
	s.files       = ["lib/cultome.rb"]
	s.homepage    = "https://github.com/csoriav/cultome_player"
	s.add_runtime_dependency "activerecord", [">= 3.2.13"]
	s.add_runtime_dependency "active_support", [">= 3.2.13"]
	s.add_runtime_dependency "mp3info", [">= 0.6.18"]
	s.add_runtime_dependency "activerecord-jdbcsqlite3-adapter", [">= 1.2.9"]
	s.add_runtime_dependency "rb-readline", [">= 0.4.2"]
	s.add_runtime_dependency "htmlentities", [">= 4.3.1"]
	s.add_runtime_dependency "json", [">= 1.7.7"]

	#s.add_development_dependency "bourne", [">== 0"]
	
	s.executables << 'cultome'
end