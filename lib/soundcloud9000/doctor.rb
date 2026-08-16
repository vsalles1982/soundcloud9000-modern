require 'net/http'
require 'uri'

module Soundcloud9000
  class Doctor
    API_HOST = 'api-v2.soundcloud.com'

    def self.run(client_id = nil)
      checks = {
        'Ruby 3.1+' => ruby_supported?,
        'curses gem' => dependency?('curses'),
        'mpv executable' => executable?('mpv'),
        'cava executable' => executable?('cava'),
        'cava configuration' => cava_config?,
        'SC_CLIENT_ID' => !client_id.to_s.empty?,
        'SoundCloud API' => api_available?(client_id)
      }

      checks.each do |name, valid|
        status = valid ? 'OK' : 'FAIL'

        puts format(
          '%-4s  %s',
          status,
          name
        )
      end

      checks.values.all?
    end

    def self.ruby_supported?
      Gem::Version.new(
        RUBY_VERSION
      ) >= Gem::Version.new('3.1')
    end

    def self.dependency?(name)
      require name
      true
    rescue LoadError
      false
    end

    def self.executable?(name)
      paths = ENV.fetch(
        'PATH',
        ''
      ).split(
        File::PATH_SEPARATOR
      )

      paths.any? do |directory|
        candidate = File.join(
          directory,
          name
        )

        File.file?(candidate) &&
          File.executable?(candidate)
      end
    end

    def self.cava_config?
      config_path = File.expand_path(
        '../../cava-soundcloud9000.conf',
        __dir__
      )

      File.file?(config_path) &&
        File.readable?(config_path)
    end

    def self.api_available?(client_id)
      return false if client_id.to_s.empty?

      uri = URI::HTTPS.build(
        host: API_HOST,
        path: '/search/tracks',
        query: URI.encode_www_form(
          client_id: client_id,
          q: 'electronic',
          limit: 1,
          linked_partitioning: 1
        )
      )

      http = Net::HTTP.new(
        uri.host,
        uri.port
      )

      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 8

      response = http.get(
        uri.request_uri
      )

      response.is_a?(
        Net::HTTPSuccess
      )
    rescue StandardError
      false
    end
  end
end
