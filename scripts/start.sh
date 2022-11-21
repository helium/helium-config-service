#!/usr/bin/env bash

export PHX_SERVER=true
export SECRET_KEY_BASE=$(mix phx.gen.secret)

while ! pg_isready -q -h $DATABASE_HOST -p 5432 -U postgres
do
  echo "pg_isready -q -h ${DATABASE_HOST} -p 5432 -U postgres"
  echo "$(date) - waiting for database to start"
  sleep 2
done

bin="_build/prod/rel/helium_config/bin/helium_config"
eval "$bin eval \"HeliumConfig.Release.migrate\""
exec "$bin" "start"
