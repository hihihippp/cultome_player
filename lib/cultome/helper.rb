require 'active_support/inflector'
require 'mp3info'

module Helper

	def require_jars
		jars_path = "#{project_path}/jars"
		Dir.entries(jars_path).each{|jar| 
		  if jar =~ /.jar\Z/
			#puts "#{jars_path}/#{jar}"
			require "#{jars_path}/#{jar}"
		  end
		}
	end

	def extract_mp3_information(file_path)
		info = nil
		begin
			Mp3Info.open(file_path) do |mp3|
				info = {
					name: mp3.tag.title,
					artist: mp3.tag.artist,
					album: mp3.tag.album,
					track: mp3.tag.tracknum,
					duration: mp3.length,
					year: mp3.tag1["year"],
					genre: mp3.tag1["genre_s"]
				}
			end

			if info[:name].nil?
				info[:name] = file_path.split('/').last
			end

			return polish(info)
		rescue
			puts "The file '#{file_path}' could not be added"
			return nil
		end
	end

	def polish(info)
		[:name, :artist, :album].each{|k| info[k] = info[k].strip.titleize unless info[k].nil? }
		[:track, :year].each{|k| info[k] = info[k].to_i if info[k] =~ /\A[\d]+\Z/ }
		info[:duration] = info[:duration].to_i

		info
	end

	def to_time(seconds)
		"#{(seconds/60).to_s.rjust(2, '0')}:#{(seconds%60).to_s.rjust(2, '0')}"
	end

	def project_path
		@_project_path || @_project_path = File.expand_path(File.dirname(__FILE__) + "/../..")
	end

	def migrations_path
		"#{ project_path }/db/migrate"
	end

	def db_logs_folder_path
		"#{ project_path }/logs"
	end

	def db_log_path
		"#{db_logs_folder_path}/db.log"
	end

	def db_adapter
		'jdbcsqlite3'
	end

	def db_file
		"#{project_path}/db_cultome.dat"
	end
end

# abrimos algunas clases con propositos utilitarios
class Array
	def to_s
		idx = 0
		self.collect{|e| "#{idx += 1} #{e}" }.join("\n")
	end
end

class String
	def blank?
		self.nil? || self.empty?
	end
end
