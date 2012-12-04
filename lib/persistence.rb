# encoding: UTF-8

require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new('logs/db.log')

ActiveRecord::Base.establish_connection(
    adapter: "jdbcsqlite3",
    database: "dev.sql"
)

class Song < ActiveRecord::Base
  attr_accessible :name, :artist_id, :album_id, :year, :track, :duration, :relative_path, :drive_id

  belongs_to :artist
  belongs_to :album
  has_and_belongs_to_many :genres
  belongs_to :drive

  def path
    "#{self.drive.path}/#{self.relative_path}"
  end

  def to_s
    ":::: Song: #{self.name} \\ Artist: #{self.artist.name unless self.artist.nil?} ::::"
  end
end

class Album < ActiveRecord::Base
  attr_accessible :name, :id

  has_many :songs
  has_many :artists, through: :songs

  def to_s
    ":::: Album: #{self.name} \\ Artist: #{self.artists.uniq.collect{|a| a.name}.join(', ')} ::::"
  end
end

class Artist < ActiveRecord::Base
  attr_accessible :name, :id

  has_many :songs
  has_many :albums, through: :songs


  def to_s
    ":::: Artist: #{self.name} ::::"
  end
end

class Genre < ActiveRecord::Base
  attr_accessible :name

  has_and_belongs_to_many :songs
end

class Drive < ActiveRecord::Base
  attr_accessible :name, :path

  has_many :songs

  def to_s
    ":::: Drive: #{self.name} => #{self.songs.size} songs => #{self.path} ::::"
  end
end
