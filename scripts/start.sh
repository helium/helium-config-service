#!/usr/bin/env bash

export PHX_SERVER=true
export DATABASE_HOST=postgres
export DATABASE_URL=ecto://postgres:postgres@postgres/helium_config_prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export PHX_HOST=localhost
export PORT=4000

while ! pg_isready -q -h $DATABASE_HOST -p 5432 -U postgres
do
  echo "pg_isready -q -h ${DATABASE_HOST} -p 5432 -U postgres"
  echo "$(date) - waiting for database to start"
  sleep 2
done

bin="_build/prod/rel/start_over/bin/start_over"
eval "$bin eval \"StartOver.Release.migrate\""
exec "$bin" "start"
