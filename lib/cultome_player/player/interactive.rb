module CultomePlayer::Player
  module Interactive

    PROMPT = "cultome> "

    # Begin a REP loop inside player.
    def begin_session
      @in_session = true
      display c5("Cultome Player v#{CultomePlayer::VERSION}")
      emit_event(:interactive_session_started)

      while in_session?
        begin
          r = execute read_command(PROMPT)
          if r.size > 1
            display c1("#{r.size} commands were executed, Showing result of the last one.")
          end

          show_response(r.last)
        rescue Exception => e
          emit_event(:interactive_exception, e)

          display c3(e.message)
          display c3(e.backtrace) if current_env == :dev
        end
      end
    end

    # Check if there is an interactive session in progress.
    #
    # @return [Boolean] True if session in progress. False otherwise.
    def in_session?
      @in_session ||= false
    end

    # Terminates a interactive session.
    def terminate_session
      @in_session = false
      save_player_configurations
      emit_event(:interactive_session_ended)
    end

    private

    def show_response(r)
      if r.respond_to?(:response_type)
        res_obj = r.send(r.response_type)
        if res_obj.respond_to?(:each)
          res_obj.each.with_index do |elem, idx|
            display c4("#{(idx + 1).to_s.ljust(3)} | #{elem.to_s}")
          end
        elsif res_obj.class == String
          display r.success? ? c1(res_obj.to_s) : c3(res_obj.to_s)
        else
          display c3("(((#{res_obj.to_s})))")
        end
      # Dont has response_type, eg has a message
      elsif r.respond_to?(:message)
        display r.success? ? c1(r.message) : c3(r.message)
      else
        display c3("!!!#{r}!!!")
      end
    end

  end
end
