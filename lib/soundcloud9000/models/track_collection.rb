require_relative 'collection'
require_relative 'track'
require_relative 'playlist'

module Soundcloud9000
  module Models
    class TrackCollection < Collection
      DEFAULT_LIMIT = 50
      HYDRATION_BATCH_SIZE = 50

      attr_reader :limit

      attr_accessor(
        :collection_to_load,
        :user,
        :playlist,
        :shuffle,
        :help,
        :query
      )

      def initialize(client)
        super

        @limit = DEFAULT_LIMIT
        @query = 'electronic'
        @collection_to_load =
          client.current_user ? :favorites : :recent
        @shuffle = false
        @help = false
        @next_href = nil
      end

      def clear
        super
        @next_href = nil
      end

      def size
        @rows.size
      end

      def clear_and_replace
        clear
        load_more
        events.trigger(:replace)
      end

      def load
        clear
        load_more
      end

      def load_more
        return if @loaded

        tracks = send(
          "#{@collection_to_load}_tracks"
        )

        @loaded = true if tracks.empty?

        append(
          tracks.map { |hash| Track.new(hash) }
        )

        @page += 1
      end

      def favorites_tracks
        return [] if @client.current_user.nil?

        response =
          if @page.zero?
            @client.get(
              "/users/#{@client.current_user.id}/track_likes",
              limit: @limit,
              linked_partitioning: 1
            )
          elsif @next_href
            @client.get(@next_href)
          else
            @loaded = true
            return []
          end

        @next_href = response['next_href']
        @loaded = true if @next_href.to_s.empty?

        extract_tracks(response)
      end

      def recent_tracks
        response = @client.get(
          '/search/tracks',
          q: @query,
          offset: @page * limit,
          limit: @limit,
          linked_partitioning: 1
        )

        extract_tracks(response)
      end

      def user_tracks
        return [] if @client.current_user.nil?

        response = @client.get(
          "/users/#{@client.current_user.id}/tracks",
          offset: @limit * @page,
          limit: @limit,
          linked_partitioning: 1
        )

        tracks = extract_tracks(response)

        if tracks.empty?
          UI::Input.error(
            "'#{@client.current_user.username}' " \
            'has not authored tracks. ' \
            'Use f for likes or s for playlists.'
          )
        end

        tracks
      end

      def playlist_tracks
        return [] if @playlist.nil?
        return [] if @page.positive?

        response = @client.get(
          "/playlists/#{@playlist.id}",
          representation: 'full'
        )

        tracks = response['tracks'] || []

        hydrate_playlist_tracks(tracks)
      end

      private

      def extract_tracks(response)
        return response if response.is_a?(Array)

        collection = response['collection'] || []

        collection.filter_map do |item|
          item['track'] || item
        end
      end

      def hydrate_playlist_tracks(tracks)
        incomplete_tracks = tracks.select do |track|
          incomplete_track?(track)
        end

        return tracks if incomplete_tracks.empty?

        details_by_id = {}

        incomplete_tracks
          .map { |track| track['id'] }
          .compact
          .each_slice(HYDRATION_BATCH_SIZE) do |ids|
            response = @client.get(
              '/tracks',
              ids: ids.join(',')
            )

            extract_tracks(response).each do |track|
              details_by_id[
                track['id'].to_i
              ] = track
            end
          end

        tracks.filter_map do |track|
          id = track['id'].to_i
          detailed_track = details_by_id[id]

          if detailed_track
            detailed_track
          elsif incomplete_track?(track)
            nil
          else
            track
          end
        end
      end

      def incomplete_track?(track)
        return true if track.nil?
        return true if track['title'].to_s.empty?
        return true if track['user'].nil?

        transcodings =
          track.dig(
            'media',
            'transcodings'
          ) || []

        transcodings.empty? &&
          track['stream_url'].to_s.empty?
      end
    end
  end
end
