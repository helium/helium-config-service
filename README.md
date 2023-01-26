# Helium Config Service

Helium Config Service (HCS) is a lightweight API service for storing
an serving shared configuration data.  Configuration data can be
queried and manipulated via gRPC and REST-style JSON APIs.  Using the
latter, clients may open long-lived streaming gRPC connections where
HCS pushes configuration updates as they occur.

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
Postgres running on localhost at port 5432.

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

Input:

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
        "lns": {
            "type": "http_roaming",
            "host": "lns1.testdomain.com",
            "port": 8080,
            "auth_header": "x-helium-auth",
            "dedupe_window": 1200
        },
        "euis": [
          {
            "dev_eui": 100,
            "app_eui": 200
          }
        ],
        "devaddr_ranges": [
          {
            "start_addr": "00000010",
            "end_addr": "0000001F"
          }
        ]
      }
    ]
  }
}
EOF
```

Output:
```bash
{"status":"success"}
```

### Get an Organization

`GET /api/v1/organizations/${OUI}` returns an Organization record,
given its OUI.

Input (assuming you created OUI 7 as in the previous example):

```bash
curl http://localhost:4000/api/v1/organizations/7
```

Output:

```bash
{
  "organization": {
    "oui": 7,
    "owner_wallet_id": "owner_id",
    "payer_wallet_id": "payer_id",
    "routes": [
      {
        "devaddr_ranges": [
          {
            "end_addr": "0000001F",
            "start_addr": "00000010"
          }
        ],
        "euis": [
          {
            "app_eui": 200,
            "dev_eui": 100
          }
        ],
        "lns": {
          "auth_header": "x-helium-auth",
          "dedupe_window": 1200,
          "host": "lns1.testdomain.com",
          "port": 8080,
          "type": "http_roaming"
        },
        "net_id": 7
      }
    ]
  }
}
```

### List Organizations

`GET /api/v1/organizations` returns the list of all Organizations.

Input:

```bash
curl http://localhost:4000/api/v1/organizations
```

Output:

```bash
[
  {
    "devaddr_constraints": [
      {
        "end_addr": "0030001A",
        "start_addr": "00010000"
      }
    ],
    "oui": 1,
    "owner_pubkey": "112udkxnN4aV9zvvyL4fb3NaTyZ3NyvkGAezm4hoAMWA99u97yuQ",
    "payer_pubkey": "11vT7ZLTrbtixBFTohUAcTdM5bEMXpY9iBqKVFZKrL7hsLhkJ4P",
    "routes": [
      {
        "devaddr_ranges": [
          {
            "end_addr": "001F0000",
            "start_addr": "00010000"
          },
          {
            "end_addr": "0030001A",
            "start_addr": "00300000"
          }
        ],
        "euis": [
          {
            "app_eui": "BEEEEEEEEEEEEEEF",
            "dev_eui": "FAAAAAAAAAAAAACE"
          }
        ],
        "id": "11111111-2222-3333-4444-555555555555",
        "max_copies": 2,
        "net_id": "000A80",
        "server": {
          "host": "server1.testdomain.com",
          "port": 8888,
          "protocol": {
            "dedupe_window": 1200,
            "flow_type": "async",
            "path": "/helium",
            "type": "http_roaming"
          }
        }
      },
      {
        "devaddr_ranges": [
          {
            "end_addr": "001F0000",
            "start_addr": "00010000"
          },
          {
            "end_addr": "0030001A",
            "start_addr": "00300000"
          }
        ],
        "euis": [
          {
            "app_eui": "BEEEEEEEEEEEEEEF",
            "dev_eui": "FAAAAAAAAAAAAACE"
          }
        ],
        "id": "22222222-2222-3333-4444-555555555555",
        "max_copies": 2,
        "net_id": "000A80",
        "server": {
          "host": "server1.testdomain.com",
          "port": 8888,
          "protocol": {
            "mapping": [
              {
                "port": 1000,
                "region": "US915"
              },
              {
                "port": 1001,
                "region": "EU868"
              },
              {
                "port": 1002,
                "region": "EU433"
              },
              {
                "port": 1003,
                "region": "CN470"
              },
              {
                "port": 1004,
                "region": "CN779"
              },
              {
                "port": 1005,
                "region": "AU915"
              },
              {
                "port": 1006,
                "region": "AS923_1"
              },
              {
                "port": 1007,
                "region": "KR920"
              },
              {
                "port": 1008,
                "region": "IN865"
              },
              {
                "port": 1009,
                "region": "AS923_2"
              },
              {
                "port": 10010,
                "region": "AS923_3"
              },
              {
                "port": 10011,
                "region": "AS923_4"
              },
              {
                "port": 10012,
                "region": "AS923_1B"
              },
              {
                "port": 10013,
                "region": "CD900_1A"
              }
            ],
            "type": "gwmp"
          }
        }
      },
      {
        "devaddr_ranges": [
          {
            "end_addr": "001F0000",
            "start_addr": "00010000"
          },
          {
            "end_addr": "0030001A",
            "start_addr": "00300000"
          }
        ],
        "euis": [
          {
            "app_eui": "BEEEEEEEEEEEEEEF",
            "dev_eui": "FAAAAAAAAAAAAACE"
          }
        ],
        "id": "33333333-2222-3333-4444-555555555555",
        "max_copies": 2,
        "net_id": "000A80",
        "server": {
          "host": "server1.testdomain.com",
          "port": 8888,
          "protocol": {
            "type": "packet_router"
          }
        }
      }
    ]
  }
]
```


### List Routes

`GET /api/v1/routes` returns the list of all routes for all
Organizations.  Helium Packet Router uses this data to route packets.

Input:

```bash
curl http://localhost:4000/api/v1/routes
```

Output:
```bash
[
  {
    "devaddr_constraints": [
      {
        "end_addr": "0030001A",
        "start_addr": "00010000"
      }
    ],
    "oui": 1,
    "owner_pubkey": "112udkxnN4aV9zvvyL4fb3NaTyZ3NyvkGAezm4hoAMWA99u97yuQ",
    "payer_pubkey": "11vT7ZLTrbtixBFTohUAcTdM5bEMXpY9iBqKVFZKrL7hsLhkJ4P",
    "routes": [
      {
        "devaddr_ranges": [
          {
            "end_addr": "001F0000",
            "start_addr": "00010000"
          },
          {
            "end_addr": "0030001A",
            "start_addr": "00300000"
          }
        ],
        "euis": [
          {
            "app_eui": "BEEEEEEEEEEEEEEF",
            "dev_eui": "FAAAAAAAAAAAAACE"
          }
        ],
        "id": "11111111-2222-3333-4444-555555555555",
        "max_copies": 2,
        "net_id": "000A80",
        "server": {
          "host": "server1.testdomain.com",
          "port": 8888,
          "protocol": {
            "dedupe_window": 1200,
            "flow_type": "async",
            "path": "/helium",
            "type": "http_roaming"
          }
        }
      },
      {
        "devaddr_ranges": [
          {
            "end_addr": "001F0000",
            "start_addr": "00010000"
          },
          {
            "end_addr": "0030001A",
            "start_addr": "00300000"
          }
        ],
        "euis": [
          {
            "app_eui": "BEEEEEEEEEEEEEEF",
            "dev_eui": "FAAAAAAAAAAAAACE"
          }
        ],
        "id": "22222222-2222-3333-4444-555555555555",
        "max_copies": 2,
        "net_id": "000A80",
        "server": {
          "host": "server1.testdomain.com",
          "port": 8888,
          "protocol": {
            "mapping": [
              {
                "port": 1000,
                "region": "US915"
              },
              {
                "port": 1001,
                "region": "EU868"
              },
              {
                "port": 1002,
                "region": "EU433"
              },
              {
                "port": 1003,
                "region": "CN470"
              },
              {
                "port": 1004,
                "region": "CN779"
              },
              {
                "port": 1005,
                "region": "AU915"
              },
              {
                "port": 1006,
                "region": "AS923_1"
              },
              {
                "port": 1007,
                "region": "KR920"
              },
              {
                "port": 1008,
                "region": "IN865"
              },
              {
                "port": 1009,
                "region": "AS923_2"
              },
              {
                "port": 10010,
                "region": "AS923_3"
              },
              {
                "port": 10011,
                "region": "AS923_4"
              },
              {
                "port": 10012,
                "region": "AS923_1B"
              },
              {
                "port": 10013,
                "region": "CD900_1A"
              }
            ],
            "type": "gwmp"
          }
        }
      },
      {
        "devaddr_ranges": [
          {
            "end_addr": "001F0000",
            "start_addr": "00010000"
          },
          {
            "end_addr": "0030001A",
            "start_addr": "00300000"
          }
        ],
        "euis": [
          {
            "app_eui": "BEEEEEEEEEEEEEEF",
            "dev_eui": "FAAAAAAAAAAAAACE"
          }
        ],
        "id": "33333333-2222-3333-4444-555555555555",
        "max_copies": 2,
        "net_id": "000A80",
        "server": {
          "host": "server1.testdomain.com",
          "port": 8888,
          "protocol": {
            "type": "packet_router"
          }
        }
      }
    ]
  }
]
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

##### Example: Streaming route updates with `grpcurl`

Fetch `helium/proto` if necessary:

```bash
$ git clone http://github.com/helium/proto

$ cd proto

$ git checkout macpie/packet_router
Branch 'macpie/packet_router' set up to track remote branch 'macpie/packet_router' from 'origin'.
Switched to a new branch 'macpie/packet_router'
```

Input:

```bash
grpcurl -d '{}' \
   --plaintext \
   --import-path ./src \
   --import-path ./src/service \
   --proto config.prot \
   localhost:50051 \
   helium.config.route/stream
```

Output:
```bash
{
  [
    {
      "netId": "7",
      "devaddrRanges": [
        {
          "startAddr": "16",
          "endAddr": "31"
        }
      ],
      "euis": [
        {
          "appEui": "200",
          "devEui": "100"
        }
      ],
      "httpRoaming": {
        "ip": "bG5zMS50ZXN0ZG9tYWluLmNvbQ==",
        "port": 8080
      }
    }
  ]
}
```

The `-d {}` option is (empty) list of parameters for creating a
`RoutesReqV1`.  `grpcurl` will hold the socket open until you kill it.
