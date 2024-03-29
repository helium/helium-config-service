#!/usr/bin/env bash

curl -v \
     -X POST http://localhost:4000/api/v1/organizations \
     -H 'content-type: application/json' \
     -d @- <<EOF
{
  "oui": 1,
  "owner_wallet_id": "owners_wallet_id",
  "payer_wallet_id": "payers_wallet_id",
  "routes": [
    {
      "devaddr_ranges": [
        {
          "end_addr": "001F",
          "start_addr": "0001"
        },
        {
          "end_addr": "003F",
          "start_addr": "0030"
        }
      ],
      "euis": [
        {
          "app_eui": "BEEEEEEEEEEEEEEF",
          "dev_eui": "FAAAAAAAAAAAAACE"
        }
      ],
      "net_id": "000007",
      "max_copies": 3,
      "oui": 1,
      "server": {
        "host": "server1.testdomain.com",
        "port": 8888,
        "protocol": {
          "auth_header": "x-helium-auth",
          "dedupe_window": 1200,
          "type": "http_roaming"
        }
      }
    },
    {
      "devaddr_ranges": [
        {
          "end_addr": "001F",
          "start_addr": "0001"
        },
        {
          "end_addr": "003F",
          "start_addr": "0030"
        }
      ],
      "euis": [
        {
          "app_eui": "BEEEEEEEEEEEEEEF",
          "dev_eui": "FAAAAAAAAAAAAACE"
        }
      ],
      "net_id": "000007",
      "max_copies": 3,
      "oui": 1,
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
              "region": "AS923_1A"
            },
            {
              "port": 10013,
              "region": "AS923_1B"
            },
            {
              "port": 10014,
              "region": "AS923_1C"
            },
            {
              "port": 10015,
              "region": "AS923_1D"
            },
            {
              "port": 10016,
              "region": "AS923_1E"
            },
            {
              "port": 10017,
              "region": "AS923_1F"
            },
            {
              "port": 10018,
              "region": "AU915_SB1"
            },
                          {
              "port": 10019,
              "region": "AU915_SB2"
            },
                          {
              "port": 10020,
              "region": "EU868_A"
            },
                          {
              "port": 10021,
              "region": "EU868_B"
            },
                          {
              "port": 10022,
              "region": "EU868_C"
            },
                          {
              "port": 10023,
              "region": "EU868_D"
            },
                          {
              "port": 10024,
              "region": "EU868_E"
            },
                          {
              "port": 10025,
              "region": "EU868_F"
            },
            {
              "port": 10026,
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
          "end_addr": "001F",
          "start_addr": "0001"
        },
        {
          "end_addr": "003F",
          "start_addr": "0030"
        }
      ],
      "euis": [
        {
          "app_eui": "BEEEEEEEEEEEEEEF",
          "dev_eui": "FAAAAAAAAAAAAACE"
        }
      ],
      "net_id": "000007",
      "max_copies": 3,
      "oui": 1,
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
EOF

echo -e "\n"
