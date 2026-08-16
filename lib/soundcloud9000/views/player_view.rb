require_relative '../time_helper'
require_relative '../ui/view'
require_relative '../models/track_collection'

module Soundcloud9000
  module Views
    class PlayerView < UI::View
      BLOCKS = [
        ' ',
        '▁',
        '▂',
        '▃',
        '▄',
        '▅',
        '▆',
        '▇',
        '█'
      ].freeze

      attr_accessor :player

      def initialize(*attrs)
        super

        padding 2
      end

      protected

      def draw
        line(
          progress + download_progress
        )

        with_color(:green) do
          line(
            (
              duration +
              ' - ' +
              status
            ).ljust(16) +
            @player.title
          )
        end

        line(track_info)

        with_color(:green) do
          line(spectrum_line)
        end
      end

      def status
        @player.playing? ? 'playing' : 'paused'
      end

      def progress
        amount = (
          @player.play_progress *
          body_width
        ).ceil

        '#' * amount
      end

      def download_progress
        remaining =
          @player.download_progress -
          @player.play_progress

        return '' unless remaining.positive?

        '.' * (
          remaining *
          body_width
        ).ceil
      end

      def track
        @player.track
      end

      def track_info
        return '' unless track

        "#{track.likes} Likes | " \
        "#{track.comments} Comments | " \
        "#{track.url}"
      end

      def duration
        TimeHelper.duration(
          @player.seconds_played.to_i *
          1000
        )
      end

      def spectrum_line
        levels = @player.spectrum

        visual = levels.map do |level|
          index = (
            level *
            (BLOCKS.length - 1)
          ).round

          index = [
            [index, 0].max,
            BLOCKS.length - 1
          ].min

          BLOCKS[index]
        end.join(' ')

        visual.center(
          body_width
        )[0, body_width]
      end
    end
  end
end
