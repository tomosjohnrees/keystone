# Keystone

A Rails 8 API.

## Development with Docker

The development environment runs entirely in Docker, so the only host
dependencies are [Docker Desktop](https://www.docker.com/products/docker-desktop/)
and `make`.

### First-time setup

1. Drop the team's `config/master.key` into your local checkout (it is
   gitignored and bind-mounted into the container). Alternatively, copy
   `.env.example` to `.env` and set `RAILS_MASTER_KEY` there.
2. Run `make setup` to build the image, install gems, and prepare the
   database.
3. Run `make up` to start the app on <http://localhost:3000>.

### Day-to-day

- `make up` — start the app in the foreground (Ctrl-C to stop).
  Use `make up-d` for a backgrounded start, then `make logs` to tail.
- `make help` — list every available target.
- `make test`, `make lint`, `make console`, `make db-migrate`, etc. — work
  whether or not the server is already running.
