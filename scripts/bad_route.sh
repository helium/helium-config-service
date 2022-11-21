#!/usr/bin/env bash

curl -v -X POST http://localhost:4000/api/v1/routes \
     -H 'content-type: application/json' \
     -d @- <<EOF
{
  "devaddr_ranges": [
    {
      "end_addr": "1000FFFF",
      "start_addr": "10000000"
    }
  ],
  "euis": [
    {
      "app_eui": "1000000000000000",
      "dev_eui": "2000000000000000"
    }
  ],
  "id": null,
  "net_id": "00000B",
  "oui": 99,
  "server": {
    "host": "newserver.testdomain.com",
    "port": 4567,
    "protocol": {
      "auth_header": "x-helium-auth",
      "dedupe_window": 1200,
      "type": "http_roaming"
    }
  }
}

EOF

echo ""
