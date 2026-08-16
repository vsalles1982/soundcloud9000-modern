require 'logger'

require_relative 'ui/canvas'
require_relative 'ui/input'
require_relative 'ui/rect'

require_relative 'controllers/track_controller'
require_relative 'controllers/player_controller'

require_relative 'models/track_collection'
require_relative 'models/player'

require_relative 'views/tracks_table'
require_relative 'views/splash'

module Soundcloud9000
  class Application
    include Controllers
    include Models
    include Views

    def initialize(client)
      $stderr.reopen('debug.log', 'w')

      @canvas = UI::Canvas.new
      @stop = false

      @splash_controller = Controller.new(
        Splash.new(
          UI::Rect.new(
            0,
            0,
            Curses.cols,
            Curses.lines
          )
        )
      )

      @track_controller = TrackController.new(
        TracksTable.new(
          UI::Rect.new(
            0,
            5,
            Curses.cols,
            Curses.lines - 5
          )
        ),
        client
      )

      @track_controller.bind_to(
        TrackCollection.new(client)
      )

      @player_controller = PlayerController.new(
        PlayerView.new(
          UI::Rect.new(
            0,
            0,
            Curses.cols,
            5
          )
        ),
        client
      )

      connect_events
    end

    def run
      @splash_controller.render
      main
    rescue StandardError => error
      log_error(error)
      show_error(error)
    ensure
      @canvas.close
    end

    def main
      first_iteration = true

      until stop?
        if first_iteration
          first_iteration = false

          safely do
            handle(UI::Input.get(0))
            @track_controller.load
            @track_controller.render
          end
        else
          safely do
            handle(UI::Input.get(-1))
          end
        end
      end
    end

    def handle(key)
      case key
      when :left,
           :right,
           :space,
           :one,
           :two,
           :three,
           :four,
           :five,
           :six,
           :seven,
           :eight,
           :nine
        @player_controller.events.trigger(
          :key,
          key
        )

      when :down,
           :up,
           :enter,
           :u,
           :f,
           :s,
           :j,
           :k,
           :m,
           :h,
           :o,
           :search,
           :next_track,
           :previous_track
        @track_controller.events.trigger(
          :key,
          key
        )
      end
    end

    def stop
      @stop = true
    end

    def stop?
      @stop == true
    end

    def self.logger
      @logger ||= Logger.new(
        'debug.log',
        3,
        1_048_576
      )
    end

    def self.get_version
      'soundcloud9000, version 0.2.0'
    end

    def self.get_help
      <<~HELP
        #{get_version}

        Usage:
          soundcloud9000
          soundcloud9000 --doctor
          soundcloud9000 --help
          soundcloud9000 --version

        Controls:
          Enter       Play selected track
          Space       Pause or continue
          Up / Down   Navigate
          /           Search
          f           Liked tracks
          s           Playlists
          m           Shuffle
          h           Help
          Ctrl+C      Exit
      HELP
    end

    private

    def connect_events
      @track_controller.events.on(:select) do |track|
        safely do
          @player_controller.play(track)
        end
      end

      @player_controller.events.on(:complete) do
        safely do
          @track_controller.next_track
        end
      end
    end

    def safely
      yield
    rescue StandardError => error
      log_error(error)
      show_error(error)
    end

    def show_error(error)
      message = friendly_error_message(error)

      UI::Input.error(
        message[0, Curses.cols - 1]
      )
    rescue StandardError
      nil
    end

    def friendly_error_message(error)
      original = error.message.to_s

      case original
      when /403/
        'SoundCloud recusou a solicitação. Verifique o client_id.'

      when /404/
        'Conteúdo não encontrado ou removido do SoundCloud.'

      when /playable transcoding/
        'Esta faixa não possui áudio disponível.'

      when /stream resolver/
        'Não foi possível resolver o streaming desta faixa.'

      when /mpv was not found/
        'mpv não foi encontrado no sistema.'

      else
        "Erro: #{original}"
      end
    end

    def log_error(error)
      self.class.logger.error(
        "#{error.class}: #{error.message}\n" \
        "#{Array(error.backtrace).join("\n")}"
      )
    end
  end
end
