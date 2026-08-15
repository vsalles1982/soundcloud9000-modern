require_relative 'user'
require_relative '../application'

module Soundcloud9000
  module Models
    class Track
      def initialize(hash)
        @hash = hash
      end

      def id
        @hash['id']
      end

      def title
        @hash['title'] || 'Untitled'
      end

      def url
        @hash['permalink_url']
      end

      def user
        @user ||= User.new(@hash['user'] || {})
      end

      def username
        user.username
      end

      def duration
        @hash['full_duration'] ||
          @hash['duration'] ||
          0
      end

      def length
        TimeHelper.duration(duration)
      end

      def likes
        @hash['likes_count'] ||
          @hash['favoritings_count'] ||
          0
      end

      def comments
        @hash['comment_count'] || 0
      end

      def stream_url
        @hash['stream_url']
      end

      def transcodings
        @hash.dig('media', 'transcodings') || []
      end

      def playable?
        !transcodings.empty? || !stream_url.to_s.empty?
      end
    end
  end
end
