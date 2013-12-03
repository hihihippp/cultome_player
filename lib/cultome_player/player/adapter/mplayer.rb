module CultomePlayer::Player::Adapter
  module MPlayer
    def play_in_player(song)
      @current_song = song
      player_running? ? loadfile(song) : start_player_with(song)
      check_playback_duration
    end

    def pause_in_player
      toggle_pause
    end

    def resume_in_player
      if paused?
        toggle_pause
        print_in_osd "=====  UNPAUSE  ====="
      else
        play_in_player current_song
      end
    end

    def stop_in_player
      send_to_player "stop"
    end

    def ff(secs=10)
      send_to_player "seek #{secs}"
    end

    def fb(secs=10)
      send_to_player "seek -#{secs}"
    end

    private

    def check_playback_duration
      send_to_player "get_time_length"
    end

    def check_time_position
      send_to_player "get_time_pos"
    end

    def print_in_osd(msg)
      send_to_player "osd_show_text '#{msg}'"
    end

    def toggle_pause
      send_to_player "pause"
    end

    def loadfile(song, append=false)
      send_to_player "loadfile '#{song.path}' #{append ? 1 : 0}"
    end

    def send_to_player(cmd)
      raise 'invalid state:player is not running' unless player_running?
      control_pipe.puts cmd
    end

    def pipe_location
      "/home/csoria/tmp/mpctr"
    end

    def control_pipe
      unless pipe_alive?
        @pipe = File.open(pipe_location, 'a+')
      end

      @pipe
    end

    def pipe_alive?
      return !(@pipe.nil? || @pipe.closed?)
    end

    def watch_playback
      Thread.new do
        while pipe_alive?
          check_time_position
          sleep 1
        end
      end
    end

    def start_player_with(song)
      start_cmd = "mplayer -slave -input file='#{pipe_location}' '#{song.path}'"
      IO.popen(start_cmd).each do |line|
        case line
        when /ANS_TIME_POSITION=([\d.]+)/
          @playback_time_position = $1.to_f
        when /ANS_length=([\d.]+)/
          @playback_time_length = $1.to_f
        when /=====  PAUSE  =====/
          @stopped = @playing = false
          @paused = true
        when /=====  UNPAUSE  =====/
          @stopped = @paused = false
          @playing = true
        when /Starting playback/
          @is_player_running = @playing = true
          @paused = @stopped = false
        when /Exiting... (End of file)/
          @is_player_running = @playing = @paused = false
          @stopped = true
          control_pipe.close
        end
      end

      watch_playback
    end

  end
end
