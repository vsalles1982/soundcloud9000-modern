require 'json'
require 'socket'
require 'tmpdir'
require_relative '../events'

module Soundcloud9000
  module Models
    # Controls mpv through JSON IPC and leaves system audio configuration alone.
    class Player
      attr_reader :track, :events

      def initialize
        @track = nil
        @events = Events.new
        @paused = false
        @stopped_pids = {}
        @socket_path = File.join(Dir.tmpdir, "soundcloud9000-#{Process.pid}.sock")
        at_exit { stop }
      end

      def play(track, location)
        stop
        @track = track
        @paused = false
        File.unlink(@socket_path) if File.exist?(@socket_path)
        @pid = Process.spawn('mpv', '--no-video', '--really-quiet', '--idle=no',
                             "--input-ipc-server=#{@socket_path}", '--', location,
                             out: File::NULL, err: File::NULL)
        watch_process(@pid)
      rescue Errno::ENOENT
        raise 'mpv was not found. Install it before starting soundcloud9000.'
      end

      def play_progress
        return 0.0 if duration <= 0
        [[seconds_played / duration, 0.0].max, 1.0].min
      end

      def duration
        mpv_duration = property('duration').to_f
        return mpv_duration if mpv_duration.positive?
        @track ? @track.duration.to_f / 1000 : 0.0
      end

      def title
        return '' unless @track
        [@track.title, @track.user.username].join(' - ')
      end

      def level
        0.0
      end

      def seconds_played
        property('time-pos').to_f
      end

      def download_progress
        1.0
      end

      def playing?
        process_alive? && !@paused
      end

      def seek_position(position)
        command('set_property', 'time-pos', duration * position.to_f * 0.1)
      end

      def rewind
        command('seek', -5, 'relative')
      end

      def forward
        command('seek', 5, 'relative')
      end

      def stop
        pid = @pid
        @stopped_pids[pid] = true if pid
        command('quit') if process_alive?
        Process.wait(pid) if pid
      rescue Errno::ECHILD
        nil
      ensure
        @pid = nil
        File.unlink(@socket_path) if File.exist?(@socket_path)
      end

      def start
        command('set_property', 'pause', false)
        @paused = false
      end

      def toggle
        @paused = !@paused
        command('set_property', 'pause', @paused)
      end

      private

      def process_alive?
        return false unless @pid
        Process.kill(0, @pid)
        true
      rescue Errno::ESRCH
        false
      end

      def socket
        40.times do
          return UNIXSocket.new(@socket_path) if File.socket?(@socket_path)
          sleep 0.025
        end
        nil
      rescue Errno::ENOENT, Errno::ECONNREFUSED
        nil
      end

      def command(*args)
        connection = socket
        return unless connection
        connection.puts JSON.generate(command: args)
      ensure
        connection&.close
      end

      def property(name)
        connection = socket
        return nil unless connection
        connection.puts JSON.generate(command: ['get_property', name])
        JSON.parse(connection.gets || '{}')['data']
      rescue JSON::ParserError
        nil
      ensure
        connection&.close
      end

      def watch_process(pid)
        Thread.new do
          while @pid == pid && process_alive?
            @events.trigger(:progress)
            sleep 0.25
          end
          Process.wait(pid)
          manually_stopped = @stopped_pids.delete(pid)
          next unless @pid == pid
          @pid = nil
          @events.trigger(:complete) unless manually_stopped
        rescue Errno::ECHILD
          nil
        end
      end
    end
  end
end
