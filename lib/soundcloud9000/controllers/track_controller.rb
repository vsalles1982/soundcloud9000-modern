require_relative 'controller'
require_relative '../time_helper'
require_relative '../ui/table'
require_relative '../ui/input'
require_relative '../models/track_collection'
require_relative '../models/user'
require_relative '../models/playlist'

module Soundcloud9000
  module Controllers
    class TrackController < Controller
      def initialize(view, client)
        super(view)

        @client = client

        events.on(:key) do |key|
          case key
          when :enter
            play_current_track

          when :next_track
            next_track

          when :previous_track
            previous_track

          when :search
            search_tracks

          when :up, :k
            @view.up

          when :down, :j
            @view.down
            @tracks.load_more if @view.bottom?

          when :u
            load_user_tracks

          when :f
            load_favorites

          when :s
            load_playlist

          when :m
            toggle_shuffle

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
        permalink = UI::Input.getstr(
          message
        ).to_s.strip

        return nil if permalink.empty?

        user_hash = @client.resolve(
          permalink
        )

        if user_hash
          Models::User.new(user_hash)
        else
          UI::Input.error(
            "No such user '#{permalink}'."
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
        elsif @view.current + 1 < @tracks.size
          @view.down
        else
          UI::Input.message(
            'Already at the final track.'
          )
          return
        end

        play_current_track
      end

      def previous_track
        if @view.current.zero?
          UI::Input.message(
            'Already at the first track.'
          )
          return
        end

        @view.up
        play_current_track
      end

      private

      def play_current_track
        track = current_track

        if track.nil?
          UI::Input.error(
            'No track is currently selected.'
          )
          return
        end

        @view.select

        events.trigger(
          :select,
          track
        )
      end

      def search_tracks
        query = UI::Input.getstr(
          'Search SoundCloud: '
        ).to_s.strip

        return if query.empty?

        @tracks.query = query
        @tracks.collection_to_load = :recent
        @tracks.clear_and_replace
      end

      def load_user_tracks
        user = fetch_user_with_message(
          'Change to SoundCloud user: '
        )

        return if user.nil?

        @client.current_user = user
        @tracks.collection_to_load = :user
        @tracks.clear_and_replace
      end

      def load_favorites
        if @client.current_user.nil?
          @client.current_user =
            fetch_user_with_message(
              "Change to SoundCloud user's favourites: "
            )
        end

        return if @client.current_user.nil?

        @tracks.collection_to_load = :favorites
        @tracks.clear_and_replace
      end

      def load_playlist
        if @client.current_user.nil?
          @client.current_user =
            fetch_user_with_message(
              'Change to SoundCloud user: '
            )
        end

        return if @client.current_user.nil?

        response = @client.get(
          "/users/#{@client.current_user.id}/" \
          'playlists_without_albums',
          limit: 50,
          linked_partitioning: 1
        )

        playlists =
          if response.is_a?(Hash)
            response['collection'] || []
          else
            response
          end

        selected_playlist =
          choose_playlist(playlists)

        return if selected_playlist.nil?

        @tracks.playlist = Models::Playlist.new(
          selected_playlist
        )

        @tracks.collection_to_load = :playlist
        @tracks.clear_and_replace
      rescue RuntimeError => error
        UI::Input.error(
          "Could not load playlists: #{error.message}"
        )
      end

      def toggle_shuffle
        @tracks.shuffle = !@tracks.shuffle

        UI::Input.message(
          "Shuffle " \
          "#{@tracks.shuffle ? 'enabled' : 'disabled'}."
        )
      end

      def choose_playlist(playlists)
        if playlists.empty?
          UI::Input.error(
            'No public playlists were found.'
          )
          return nil
        end

        selected = 0
        visible_rows = [
          Curses.lines - 6,
          15
        ].min

        height = visible_rows + 4
        width = [
          Curses.cols - 4,
          90
        ].min

        top = (
          Curses.lines - height
        ) / 2

        left = (
          Curses.cols - width
        ) / 2

        window = Curses::Window.new(
          height,
          width,
          top,
          left
        )

        window.keypad(true)

        loop do
          draw_playlist_menu(
            window,
            playlists,
            selected,
            visible_rows,
            width
          )

          key = window.getch

          case key
          when Curses::KEY_UP, 'k'
            selected -= 1 if selected.positive?

          when Curses::KEY_DOWN, 'j'
            if selected < playlists.length - 1
              selected += 1
            end

          when Curses::KEY_ENTER,
               Curses::KEY_CTRL_J,
               10,
               13
            return playlists[selected]

          when 27, 'q'
            return nil
          end
        end
      ensure
        window&.close
      end

      def draw_playlist_menu(
        window,
        playlists,
        selected,
        visible_rows,
        width
      )
        window.clear
        window.box('|', '-')

        window.setpos(1, 2)
        window.addstr(
          'Choose playlist — arrows + Enter'
        )

        offset =
          if selected >= visible_rows
            selected - visible_rows + 1
          else
            0
          end

        visible_playlists =
          playlists.slice(
            offset,
            visible_rows
          ) || []

        visible_playlists.each_with_index do |playlist, row|
          index = offset + row
          title = playlist['title'].to_s
          prefix = index == selected ? '> ' : '  '

          text = "#{prefix}#{title}"[
            0,
            width - 4
          ]

          window.setpos(
            row + 3,
            2
          )

          if index == selected
            window.attron(
              Curses::A_REVERSE
            ) do
              window.addstr(text)
            end
          else
            window.addstr(text)
          end
        end

        window.refresh
      end

      def show_help
        height = [
          Curses.lines - 2,
          34
        ].min

        width = [
          Curses.cols - 2,
          84
        ].min

        top = (
          Curses.lines - height
        ) / 2

        left = (
          Curses.cols - width
        ) / 2

        window = Curses::Window.new(
          height,
          width,
          top,
          left
        )

        window.keypad(true)

        window.attrset(
          Curses.color_pair(4) |
          Curses::A_REVERSE |
          Curses::A_BOLD
        )

        help_text = <<~HELP
          SoundCloud9000 — Shortcuts

          Enter       Play selected track
          Space       Play or pause
          n           Next track
          p           Previous track
          Up / k      Move selection up
          Down / j    Move selection down
          Left        Rewind 5 seconds
          Right       Forward 5 seconds
          1–9         Jump to a percentage

          /           Search tracks or artists
          u           Load tracks from a user
          f           Return to liked tracks
          s           Choose a playlist
          m           Toggle shuffle
          h           Open this help
          Ctrl+C      Exit
        HELP

        window.setpos(1, 2)

        help_text.each_line do |line|
          break if window.cury >= height - 2

          window.addstr(
            line.chomp[
              0,
              width - 4
            ]
          )

          window.setpos(
            window.cury + 1,
            2
          )
        end

        window.box('|', '-')
        window.refresh
        window.getch
      ensure
        window&.close
        @tracks.clear_and_replace
      end
    end
  end
end
