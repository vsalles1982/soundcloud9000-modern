require_relative 'controller'
require_relative '../time_helper'
require_relative '../ui/table'
require_relative '../ui/input'
require_relative '../models/track_collection'
require_relative '../models/user'

module Soundcloud9000
  module Controllers
    class TrackController < Controller
      def initialize(view, client)
        super(view)

        @client = client

        events.on(:key) do |key|
          case key
          when :enter
            @view.select
            events.trigger(:select, current_track)

          when :search
            query = UI::Input.getstr(
              'Search SoundCloud: '
            ).to_s.strip

            unless query.empty?
              @tracks.query = query
              @tracks.collection_to_load = :recent
              @tracks.clear_and_replace
            end

          when :up, :k
            @view.up

          when :down, :j
            @view.down
            @tracks.load_more if @view.bottom?

          when :u
            user = fetch_user_with_message(
              'Change to SoundCloud user: '
            )

            unless user.nil?
              @client.current_user = user
              @tracks.collection_to_load = :user
              @tracks.clear_and_replace
            end

          when :f
            if @client.current_user.nil?
              @client.current_user = fetch_user_with_message(
                "Change to SoundCloud user's favourites: "
              )
            end

            unless @client.current_user.nil?
              @tracks.collection_to_load = :favorites
              @tracks.clear_and_replace
            end

          when :s
            @view.clear

            if @client.current_user.nil?
              @client.current_user = fetch_user_with_message(
                'Change to SoundCloud user: '
              )
            end

            unless @client.current_user.nil?
              playlist_name = UI::Input.getstr(
                'Change to SoundCloud playlist: '
              ).to_s.strip

              playlist_path =
                "#{@client.current_user.permalink}/sets/#{playlist_name}"

              playlist_response = @client.resolve(playlist_path)

              if playlist_response.nil?
                UI::Input.error(
                  "No such playlist '#{playlist_name}' for " \
                  "#{@client.current_user.username}"
                )
              else
                @tracks.playlist = Models::Playlist.new(
                  playlist_response
                )
                @tracks.collection_to_load = :playlist
                @tracks.clear_and_replace
              end
            end

          when :m
            @tracks.shuffle = !@tracks.shuffle

            UI::Input.message(
              "Shuffle #{@tracks.shuffle ? 'enabled' : 'disabled'}."
            )

          when :h
            show_help

          when :o
            UI::Input.message(
              'Track ordering is not implemented yet.'
            )
          end
        end
      end

      def fetch_user_with_message(message)
        permalink = UI::Input.getstr(message).to_s.strip
        return nil if permalink.empty?

        user_hash = @client.resolve(permalink)

        if user_hash
          Models::User.new(user_hash)
        else
          UI::Input.error(
            "No such user '#{permalink}'. Use u to try again."
          )
          nil
        end
      end

      def current_track
        @tracks[@view.current]
      end

      def bind_to(tracks)
        @tracks = tracks
        @view.bind_to(tracks)
      end

      def load
        @tracks.load
      end

      def next_track
        if @tracks.shuffle
          @view.random
        else
          @view.down
        end

        @view.select
        events.trigger(:select, current_track)
      end

      private

      def show_help
        @tracks.help = !@tracks.help

        unless @tracks.help
          @tracks.clear_and_replace
          return
        end

        height = [Curses.lines - 2, 32].min
        width = [Curses.cols - 2, 84].min
        top = (Curses.lines - height) / 2
        left = (Curses.cols - width) / 2

        window = Curses::Window.new(
          height,
          width,
          top,
          left
        )

        window.attrset(
          Curses.color_pair(4) |
          Curses::A_REVERSE |
          Curses::A_BOLD
        )

        help_text = <<~HELP
          SoundCloud9000 — Shortcuts

          Enter       Play selected track
          Space       Play or pause
          Up / k      Previous item
          Down / j    Next item
          Left        Rewind 5 seconds
          Right       Forward 5 seconds
          1–9         Jump to a percentage of the track

          /           Search tracks, artists or genres
          u           Load tracks from a user
          f           Return to the user's liked tracks
          s           Open one of the user's playlists
          m           Toggle shuffle mode
          h           Open or close this help
          Ctrl+C      Exit
        HELP

        window.setpos(1, 2)

        help_text.each_line do |line|
          break if window.cury >= height - 2

          window.addstr(
            line.chomp[0, width - 4]
          )

          window.setpos(
            window.cury + 1,
            2
          )
        end

        window.box('|', '-')
        window.refresh
        window.getch
        window.close

        @tracks.help = false
        @tracks.clear_and_replace
      end
    end
  end
end
