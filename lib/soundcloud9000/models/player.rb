require 'json'
require 'socket'
require 'tmpdir'

require_relative '../events'
require_relative 'spectrum'

module Soundcloud9000
  module Models
    class Player
      attr_reader :track, :events

      def initialize
        @track = nil
        @events = Events.new
        @paused = false
        @pid = nil
        @manually_stopped = {}
        @spectrum_reader = Spectrum.new

        @socket_path = File.join(
          Dir.tmpdir,
          "soundcloud9000-#{Process.pid}.sock"
        )

        at_exit do
          shutdown
        end
      end

      def play(track, location)
        stop

        @track = track
        @paused = false

        remove_socket

        @pid = Process.spawn(
          'mpv',
          '--no-video',
          '--really-quiet',
          '--idle=no',
          '--keep-open=no',
          '--loop-file=no',
          '--audio-display=no',
          "--input-ipc-server=#{@socket_path}",
          '--',
          location,
          out: File::NULL,
          err: File::NULL
        )

        watch_process(@pid)
        update_progress(@pid)
      rescue Errno::ENOENT
        raise(
          'mpv was not found. Install it before starting soundcloud9000.'
        )
      end

      def spectrum
        @spectrum_reader.levels
      end

      def play_progress
        total = duration
        return 0.0 if total <= 0

        progress = seconds_played / total

        [
          [progress, 0.0].max,
          1.0
        ].min
      end

      def duration
        mpv_duration = property(
          'duration'
        ).to_f

        return mpv_duration if mpv_duration.positive?
        return 0.0 unless @track

        @track.duration.to_f / 1000
      end

      def title
        return '' unless @track

        [
          @track.title,
          @track.user.username
        ].join(' - ')
      end

      def level
        spectrum.max.to_f
      end

      def seconds_played
        property(
          'time-pos'
        ).to_f
      end

      def download_progress
        1.0
      end

      def playing?
        process_alive?(@pid) && !@paused
      end

      def seek_position(position)
        target = duration *
                 position.to_f *
                 0.1

        command(
          'set_property',
          'time-pos',
          target
        )
      end

      def rewind
        command(
          'seek',
          -5,
          'relative'
        )
      end

      def forward
        command(
          'seek',
          5,
          'relative'
        )
      end

      def stop
        pid = @pid
        return if pid.nil?

        @manually_stopped[pid] = true
        command('quit')

        begin
          Process.kill(
            'TERM',
            pid
          ) if process_alive?(pid)
        rescue Errno::ESRCH
          nil
        end

        @pid = nil if @pid == pid
        @paused = false

        remove_socket
      end

      def shutdown
        stop
        @spectrum_reader.stop
      end

      def start
        return unless @pid

        command(
          'set_property',
          'pause',
          false
        )

        @paused = false
      end

      def toggle
        return unless @pid

        @paused = !@paused

        command(
          'set_property',
          'pause',
          @paused
        )
      end

      private

      def process_alive?(pid)
        return false if pid.nil?

        Process.kill(
          0,
          pid
        )

        true
      rescue Errno::ESRCH
        false
      end

      def socket
        40.times do
          if File.socket?(@socket_path)
            return UNIXSocket.new(
              @socket_path
            )
          end

          sleep 0.025
        end

        nil
      rescue Errno::ENOENT,
             Errno::ECONNREFUSED
        nil
      end

      def command(*arguments)
        connection = socket
        return nil unless connection

        connection.puts(
          JSON.generate(
            command: arguments
          )
        )

        true
      rescue Errno::EPIPE,
             Errno::ECONNRESET
        nil
      ensure
        connection&.close
      end

      def property(name)
        connection = socket
        return nil unless connection

        connection.puts(
          JSON.generate(
            command: [
              'get_property',
              name
            ]
          )
        )

        response = JSON.parse(
          connection.gets || '{}'
        )

        response['data']
      rescue JSON::ParserError,
             Errno::EPIPE,
             Errno::ECONNRESET
        nil
      ensure
        connection&.close
      end

      def watch_process(pid)
        Thread.new do
          begin
            Process.wait(pid)
          rescue Errno::ECHILD
            nil
          end

          manual = @manually_stopped.delete(
            pid
          )

          next unless @pid == pid

          @pid = nil
          @paused = false

          remove_socket

          @events.trigger(
            :complete
          ) unless manual
        rescue StandardError => error
          Soundcloud9000::Application.logger.error(
            "Player watcher: #{error.class}: " \
            "#{error.message}"
          )
        end
      end

      def update_progress(pid)
        Thread.new do
          loop do
            break unless @pid == pid
            break unless process_alive?(pid)

            @events.trigger(
              :progress
            )

            sleep 0.08
          end
        rescue StandardError => error
          Soundcloud9000::Application.logger.error(
            "Player progress: #{error.class}: " \
            "#{error.message}"
          )
        end
      end

      def remove_socket
        return unless File.exist?(
          @socket_path
        )

        File.unlink(
          @socket_path
        )
      rescue Errno::ENOENT
        nil
      end
    end
  end
end

