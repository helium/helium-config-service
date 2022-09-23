# Helium Config Service

Helium Config Service (HCS) is a lightweight API service for storing
an serving shared configuration data.  Configuration data can be
queried and manipulated via a REST-style JSON API.  It is also served
up, read-only, through a gRPC API.  For the latter, the intent is for
consumer services, like Helium Packet Router, to open long-lived
streaming gRPC connections where HCS pushes configuration updates as
they occur.

## Building

### Requirements

HCS requires [`protoc`](https://grpc.io/docs/protoc-installation/) and
the `protoc-gen-elixir` plugin to generate Elixir code from Protocol
Buffer definitions. Install `protoc` using your operating system's
package manager (on Debian, it's `apt-get install
protobuf-compiler`). Install `protoc-gen-elixir` using `mix`, like
this:

```bash
$ mix escript.install hex protobuf
```

HCS requires a PostgreSQL database.  It has been built and tested with
PostgreSQL version 13.4.

HCS uses [`libp2p_crypto`](https://github.com/helium/libp2p-crypto) to
verify signatures and manipulate encryption keys. On a Debian host,
`libp2p_crypto` requires these packages:

```bash
$ apt-get install -y -q \
	build-essential \
	bison \
	flex \
	git \
	gzip \
	autotools-dev \
	automake \
	libtool \
	pkg-config \
	cmake \
	libsodium-dev
```


### `Mix` Environments

#### `dev`

`dev` is assumed to be the environment where code is written and
manually tested, usually a laptop or desktop computer, and has
Postgres running on localhost at port 5432.

#### `test`

`test` is the environment where `mix test` runs. It is assumed to have
Postgress running on localhost at port 5432.

#### `prod`

The `prod` mix environment has deliberately few compile-time settings.
It defers most configuration decisions to `config/runtime.exs` where
most settings are taken from OS environment variables.  This makes
`prod` most suitable for containerized environments, like
docker-compose.

To run HCS with `prod`, the OS environment should, at a minimum,
define these variables:

```bash
export PHX_SERVER=true
export DATABASE_HOST=postgres
export DATABASE_URL=ecto://postgres_user:postgres_password@postgres_hostname/helium_config_prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export PHX_HOST=localhost
export PORT=4000
```

### Locally

Assuming you have PostgreSQL installed and running on localhost at
port 5432, you can run HCS locally by building the code and starting
the application with `mix` in the usual way:

```bash
git clone https://github.com/helium/helium-config-service
cd helium-config-service
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

The JSON API will be available on localhost at port 4000.

The gRPC API will be available on localhost at port 50051.

### Docker Compose

The HCS code includes a docker-compose.yml file that defines one
Postgres and one HCS instance.  You can run them locally, like this:

```bash
docker build -t hcs:latest .
docker-compose up
```

Note that HCS uses the `prod` mix environment for compilation, meaning
that most configuration settings will be taken from OS environment
variables.

Once up, the JSON and gRPC APIs will be available on all network
interfaces of the host machine at ports 4000 and 50051, respectively.


## The JSON API

### Create an Organization

`POST /api/v1/organizations` creates a new Organization record.

```bash
curl -X POST http://localhost:4000/api/v1/organizations \
 -H "content-type: application/json" \
 --data-binary @- <<EOF
{
  "organization": {
    "oui": 7,
    "owner_wallet_id": "owner_id",
    "payer_wallet_id": "payer_id",
    "routes": [
      {
        "net_id": 7,
        "lns_address": "lns1.testdomain.com",
        "protocol": "http",
        "euis": [
          {
            "dev_eui": 100,
            "app_eui": 200
          }
        ],
        "devaddr_ranges": [
          {
            "start_addr": 200,
            "end_addr": 300
          }
        ]
      }
    ]
  }
}
EOF
```

### Get an Organization

`GET /api/v1/organizations/${OUI}` returns an Organization record,
given its OUI.

```
$ curl http://localhost:4000/api/v1/organizations/7
{
  "organization": {
    "oui": 7,
    "owner_wallet_id": "owner_id",
    "payer_wallet_id": "payer_id",
    "routes": [
      {
        "devaddr_ranges": [
          {
            "end_addr": "0000012C",
            "start_addr": "000000C8"
          }
        ],
        "euis": [
          {
            "app_eui": 200,
            "dev_eui": 100
          }
        ],
        "lns_address": "lns1.testdomain.com",
        "net_id": 7,
        "protocol": "http"
      }
    ]
  }
}

```

### List Organizations

`GET /api/v1/organizations` returns the list of all Organizations.

```bash
$ curl http://localhost:4000/api/v1/organizations

{
  "organizations": [
    {
      "oui": 7,
      "owner_wallet_id": "owner_id",
      "payer_wallet_id": "payer_id",
      "routes": [
        {
          "devaddr_ranges": [
            {
              "end_addr": "0000012C",
              "start_addr": "000000C8"
            }
          ],
          "euis": [
            {
              "app_eui": 200,
              "dev_eui": 100
            }
          ],
          "lns_address": "lns1.testdomain.com",
          "net_id": 7,
          "protocol": "http"
        }
      ]
    }
  ]
}
```

### List Routes

`GET /api/v1/routes` returns the list of all routes for all
Organizations.  Helium Packet Router uses this data to route packets.

```bash
$ curl http://localhost:4000/api/v1/routes
{
  "routes": [
    {
      "devaddr_ranges": [
        {
          "end_addr": "0000012C",
          "start_addr": "000000C8"
        }
      ],
      "euis": [
        {
          "app_eui": 200,
          "dev_eui": 100
        }
      ],
      "lns_address": "lns1.testdomain.com",
      "net_id": 7,
      "protocol": "http"
    }
  ]
}
```

## The gRPC API

### `helium_config.config_service`

This is the gRPC service served by HCS.  You can find the formal
definition
[here](https://github.com/helium/proto/blob/macpie/packet_router/src/service/config.proto)

It offers the following RPC calls:

#### `route_updates`

`route_updates` takes a single `RoutesReqV1` request and returns a
stream of `RoutesResV1`.

`RoutesReqV1` has no fields to fill out.  It is essentially an "empty
envelope" sent by a client to initiate a streaming response from the
server.

`RoutesResV1` contains a single field, `routes`, that contains a
complete list of all route records known to HCS.

Upon receipt of a `RoutesReqV1`, HCS responds with a single
`RoutesResV1` and then holds the socket open.  If an update to an
Organization occurs, or a new Organization is created, the HCS sends
another `RoutesResV1` containing the entire data set, including the
new data.

##### Example: Calling `route_updates` with `grpcurl`

```bash
$ git clone http://github.com/helium/proto

$ cd proto

$ git checkout macpie/packet_router
Branch 'macpie/packet_router' set up to track remote branch 'macpie/packet_router' from 'origin'.
Switched to a new branch 'macpie/packet_router'


$ grpcurl -d '{}' \
   --plaintext \
   --import-path ./src/service \
   --proto config.proto \
   localhost:50051 \
   helium.config.config_service/route_updates
{
  "routes": [
    {
      "netId": "7",
      "devaddrRanges": [
        {
          "startAddr": "200",
          "endAddr": "300"
        }
      ],
      "euis": [
        {
          "appEui": "200",
          "devEui": "100"
        }
      ],
      "lns": "bG5zMS50ZXN0ZG9tYWluLmNvbQ==",
      "protocol": "http"
    }
  ]
}
```

The `-d {}` option is (empty) list of parameters for creating a
`RoutesReqV1`.  `grpcurl` will hold the socket open until you kill it.

