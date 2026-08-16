require_relative '../spec_helper'
require_relative '../../lib/soundcloud9000/controllers/track_controller'

module Soundcloud9000
  module Controllers
    describe TrackController do
      let(:tracks) do
        mock('tracks')
      end

      let(:table) do
        mock('table')
      end

      let(:client) do
        mock('client')
      end

      subject do
        TrackController.new(
          table,
          client
        )
      end

      before do
        table.expects(
          :bind_to
        ).with(tracks)

        subject.bind_to(tracks)
      end

      it 'plays the selected track with Enter' do
        table.stubs(
          :current
        ).returns(0)

        table.expects(:select)

        tracks.expects(
          :[]
        ).with(0).returns(:track)

        subject.events.trigger(
          :key,
          :enter
        )
      end

      it 'moves selection up' do
        table.expects(:up)

        subject.events.trigger(
          :key,
          :up
        )
      end

      it 'moves down and loads another page' do
        table.expects(:down)

        table.expects(
          :bottom?
        ).returns(true)

        tracks.expects(:load_more)

        subject.events.trigger(
          :key,
          :down
        )
      end

      it 'searches for tracks' do
        UI::Input.expects(
          :getstr
        ).returns('Richie Hawtin')

        tracks.expects(
          :query=
        ).with('Richie Hawtin')

        tracks.expects(
          :collection_to_load=
        ).with(:recent)

        tracks.expects(
          :clear_and_replace
        )

        subject.events.trigger(
          :key,
          :search
        )
      end

      it 'loads tracks from another user' do
        UI::Input.expects(
          :getstr
        ).returns('plastikman')

        client.expects(
          :resolve
        ).with('plastikman').returns(
          {
            'id' => 1,
            'username' => 'Plastikman'
          }
        )

        client.expects(
          :current_user=
        ).with(
          instance_of(
            Models::User
          )
        )

        tracks.expects(
          :collection_to_load=
        ).with(:user)

        tracks.expects(
          :clear_and_replace
        )

        subject.events.trigger(
          :key,
          :u
        )
      end

      it 'returns to liked tracks' do
        user = mock('user')

        client.stubs(
          :current_user
        ).returns(user)

        tracks.expects(
          :collection_to_load=
        ).with(:favorites)

        tracks.expects(
          :clear_and_replace
        )

        subject.events.trigger(
          :key,
          :f
        )
      end

      it 'plays the next sequential track' do
        tracks.stubs(
          :shuffle
        ).returns(false)

        tracks.stubs(
          :size
        ).returns(2)

        table.stubs(
          :current
        ).returns(0)

        table.expects(:down)
        table.expects(:select)

        tracks.expects(
          :[]
        ).with(0).returns(:track)

        subject.next_track
      end

      it 'chooses a random next track in shuffle mode' do
        tracks.stubs(
          :shuffle
        ).returns(true)

        table.stubs(
          :current
        ).returns(1)

        table.expects(:random)
        table.expects(:select)

        tracks.expects(
          :[]
        ).with(1).returns(:track)

        subject.next_track
      end

      it 'plays the previous track' do
        table.stubs(
          :current
        ).returns(1)

        table.expects(:up)
        table.expects(:select)

        tracks.expects(
          :[]
        ).with(1).returns(:track)

        subject.previous_track
      end
    end
  end
end
