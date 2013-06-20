
module CultomePlayer::Extras::LastFm
    module SimilarTo

        # Register similar command.
        def self.included(base)
            CultomePlayer::Player.command_registry << :similar
            CultomePlayer::Player.command_help_registry[:similar] = {
                help: "Look in last.fm for similar artists or songs", 
                params_format: "<object>",
                usage: <<-HELP
There are two primary uses for this plugin:
    * find similar songs to the current song
    * find similar artists of the artist of the current song

To search for similar songs you dont need extra parameters, but if you wish to be explicit you can pass '@song' as parameter.

To search for artist the parameter '@artist' is required.

When the results are parsed successfully from Last.fm the first time, the results are stored in the local database, so, successives calls of this command, for the same song or artist dont require internet access.

                HELP
            }
        end

        # Display a list with similar artist or album of the give song or artist and shows a list with them, separing the one within our library.
        #
        # @param params [List<Hash>] With parsed player's object information. Only @artist and @song are valid.
        def similar(params=[])
            raise 'invalid parameter' if !params.empty? && params.find{|p| p[:type] == :object}.nil?
            raise 'no active playback' if current_song.nil?

                song_name = current_song.name
                artist_name = current_song.artist.name
                song_id = current_song.id
                artist_id = current_song.artist.id

                type = params.empty? ? :song : params.find{|p| p[:type] == :object}[:value]
                query_info = define_lastfm_query(type, song_name, artist_name)

                in_db = check_in_db(query_info)

                if in_db.empty?
                    json = request_to_lastfm(query_info)

                    raise 'Houston! we had a problem extracting Last.fm information' if json.nil?

                    if !json['similarartists'].nil?
                        # get the information form the reponse
                        artists = json['similarartists']['artist'].collect do |a|
                            {
                                artist: a['name'],
                                artist_url: a['url'],
                                similar_to: 'artist'
                            }
                        end

                        # salvamos los similares
                        store_similar_artists(artist_id, artists)

                        artists_in_library = find_artists_in_library(artists)
                        show_artist(artist_name, artists, artists_in_library)

                        return artists, artists_in_library
                    elsif !json['similartracks'].nil?
                        # convierte los datos del request en un hash mas manejable
                        tracks = json['similartracks']['track'].collect do |t|
                            {
                                track: t['name'],
                                artist: t['artist']['name'],
                                track_url: t['url'],
                                artist_url: t['artist']['url'],
                                similar_to: 'track'
                            }
                        end

                        # salvamos los similares
                        store_similar_tracks(song_id, tracks)
                        tracks_in_library = find_tracks_in_library(tracks)
                        show_tracks(song_name, tracks, tracks_in_library)

                        return tracks, tracks_in_library
                    else
                        # seguramente un error
                        display(c2("Problem! #{json['error']}: #{json['message']}"))
                    end
                else
                    # trabajamos con datos de la db
                    if query_info[:method] == GET_SIMILAR_ARTISTS_METHOD
                        artists_in_library = find_artists_in_library(in_db)
                        show_artist(artist_name, in_db, artists_in_library)

                        return in_db, artists_in_library
                    elsif query_info[:method] == GET_SIMILAR_TRACKS_METHOD
                        tracks_in_library = find_tracks_in_library(in_db)
                        show_tracks(song_name, in_db, tracks_in_library)

                        return in_db, tracks_in_library
                    end
                end
        end

        private

        # Check if previously the similars has been inserted.
        #
        # @param (see #define_lastfm_query)
        # @return [List<Similar>] A list with the result of the search for similars for this criterio.
        def check_in_db(query_info)
            if query_info[:method] == GET_SIMILAR_ARTISTS_METHOD
                artist = CultomePlayer::Model::Artist.includes(:similars).find_by_name(query_info[:artist])
                return artist.similars unless artist.nil?
                return []
            elsif query_info[:method] == GET_SIMILAR_TRACKS_METHOD
                track = CultomePlayer::Model::Song.includes(:similars).find_by_name(query_info[:track])
                return track.similars unless track.nil?
                return []
            end
        end

        # For the given artist list, find in the library if that artist exists, if exist, remove it from the parameter list.
        # @note This method change the artist parameter.
        #
        # @param artists [List<Hash>] Contains the transformed artist information.
        # @return [List<Artist>] The artist found in library.
        def find_artists_in_library(artists)
            in_library = []

                display 'Fetching similar artist from library'

            artists.keep_if do |a|
                artist = CultomePlayer::Model::Artist.find_by_name(a[:artist])
                if artist.nil? 
                    # dejamos los artistas que no esten en nuestra library
                    true
                else
                    in_library << artist
                    false
                end
            end

            return in_library
        end

        # For the given tracks list, find in the library if that track exists, if exist, remove it from the parameter list.
        # @note This method change the tracks parameter.
        #
        # @param tracks [List<Hash>] Contains the transformed track information.
        # @return [List<Song>] The songs found in library.
        def find_tracks_in_library(tracks)
            in_library = []

                display 'Fetching similar tracks from library',

            tracks.keep_if do |t|
                song = CultomePlayer::Model::Song.joins(:artist).where('songs.name = ? and artists.name = ?', t[:track], t[:artist]).to_a
                if song.empty?
                    # aqui meter a similars
                    true
                else
                    in_library << song
                    false
                end
            end

            return in_library.flatten
        end

        # Display a list with similar tracks found and not found in library.
        #
        # @param song [Song] The song compared.
        # @param tracks [List<Hash>] The song transformed information.
        # @param tracks_in_library [List<Song>] The similari songs found in library.
        def show_tracks(song, tracks, tracks_in_library)
            display c4("Similar tracks to #{song}") unless tracks.empty?
            tracks.each{|a| display c4("  #{a[:track]} / #{a[:artist]}") } unless tracks.empty?

            display c4("Similar tracks to #{song} in library") unless tracks_in_library.empty?
            display c4(tracks_in_library) unless tracks_in_library.empty?
            #tracks_in_library.each{|a| display("  #{a.name} / #{a.artist.name}") } unless tracks_in_library.empty?

            if tracks.empty? && tracks_in_library.empty?
                display c2("No similarities found for #{song}") 
            else
                player.focus = tracks_in_library
            end
        end

        # Display a list with similar artist found and not found in library.
        #
        # @param artist [Artist] The artist compared.
        # @param artists [List<Hash>] The artist transformed information.
        # @param artists_in_library [List<Artist>] The similari artist found in library.
        def show_artist(artist, artists, artists_in_library)
            display c4("Similar artists to #{artist}") unless artists.empty?
            artists.each{|a| display c4("  #{a[:artist]}") } unless artists.empty?

            display c4("Similar artists to #{artist} in library") unless artists_in_library.empty?
            artists_in_library.each{|a| display("  #{a.name}") } unless artists_in_library.empty?

            display c2("No similarities found for #{artist}") if artists.empty? && artists_in_library.empty?
        end

        def store_similar_artists(artist_id, artists)
            artists.each do |a|
                CultomePlayer::Model::Artist.find(artist_id).similars.create(a)
            end
        end

        def store_similar_tracks(track_id, tracks)
            tracks.each do |t|
                CultomePlayer::Model::Song.find(track_id).similars.create(t)
            end
        end
    end
end
