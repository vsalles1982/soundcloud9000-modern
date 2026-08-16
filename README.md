# soundcloud9000-modern

Modernization of the original Ruby/curses SoundCloud terminal player.

## Phase 1

- Retains the original terminal UI, controllers, models, views and shortcuts.
- Replaces Audite, PortAudio and direct ALSA access with `mpv` over JSON IPC.
- Streams without downloading a partial MP3 into the home directory.
- Replaces the removed `URI.escape` API.
- Does not change PipeWire, PulseAudio, ALSA or Bluetooth configuration.

## Arch Linux prerequisites

```bash
sudo pacman -S --needed ruby mpv ncurses
gem install --user-install bundler
bundle config set --local path vendor/bundle
bundle install
```

Check the local environment without exposing or requiring the key:

```bash
bundle exec ruby ./soundcloud9000 --doctor
```

Then run:

```bash
SC_CLIENT_ID="YOUR_CLIENT_ID" bundle exec ruby ./soundcloud9000
```

Never commit a client ID, OAuth token or browser credential.

## Status

Phases 1 and 2 are implemented: the obsolete audio chain is gone and the
client resolves current progressive/HLS transcodings, with a legacy fallback.
Live validation against SoundCloud remains dependent on a valid client ID.
