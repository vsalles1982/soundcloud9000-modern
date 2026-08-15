require 'net/http'
require 'json'
require 'uri'

module Soundcloud9000
  class Client
    DEFAULT_LIMIT = 50
    API_HOST = 'api-v2.soundcloud.com'

    attr_reader :client_id, :current_user
    attr_writer :current_user

    def initialize(client_id)
      @client_id = client_id
      @current_user = nil
    end

    def tracks(page = 1, limit = DEFAULT_LIMIT)
      get(
        '/search/tracks',
        q: 'electronic',
        offset: (page - 1) * limit,
        limit: limit,
        linked_partitioning: 1
      )
    end

    def resolve(permalink)
      url =
        if permalink.start_with?('http://', 'https://')
          permalink
        else
          "https://soundcloud.com/#{permalink}"
        end

      response = get('/resolve', url: url)

      return response if response.is_a?(Hash) && response['kind']

      if response.is_a?(Hash) && response['location']
        location_uri = URI.parse(response['location'])
        return get(location_uri.path)
      end

      nil
    rescue RuntimeError, JSON::ParserError, URI::InvalidURIError
      nil
    end

    def request(type, path, params = {})
      request_params = params.merge(client_id: client_id)
      query = URI.encode_www_form(request_params)

      Net::HTTP.start(API_HOST, 443, use_ssl: true) do |http|
        http.request(type.new("#{path}?#{query}"))
      end
    end

    def get(path, params = {})
      response = request(Net::HTTP::Get, path, params)

      unless response.is_a?(Net::HTTPSuccess) ||
             response.is_a?(Net::HTTPRedirection)
        raise "SoundCloud API error #{response.code}"
      end

      JSON.parse(response.body)
    end

    def stream_url(track)
      transcoding = preferred_transcoding(track.transcodings)

      if transcoding
        return resolve_transcoding_url(transcoding.fetch('url'))
      end

      return legacy_stream_location(track.stream_url) if track.stream_url

      raise 'This track does not expose a playable transcoding.'
    end

    private

    def preferred_transcoding(transcodings)
      transcodings.find do |item|
        item.dig('format', 'protocol') == 'progressive'
      end || transcodings.find do |item|
        item.dig('format', 'protocol') == 'hls'
      end
    end

    def resolve_transcoding_url(url)
      uri = URI.parse(url)
      query = URI.decode_www_form(uri.query.to_s)

      unless query.any? { |key, _value| key == 'client_id' }
        query << ['client_id', client_id]
      end

      uri.query = URI.encode_www_form(query)

      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise "SoundCloud stream resolver error #{response.code}"
      end

      JSON.parse(response.body).fetch('url')
    end

    def legacy_stream_location(url)
      uri = URI.parse(url)
      response = request(Net::HTTP::Get, uri.path)

      if response.is_a?(Net::HTTPRedirection)
        response['location']
      else
        raise "Legacy stream resolver error #{response.code}"
      end
    end
  end
end
