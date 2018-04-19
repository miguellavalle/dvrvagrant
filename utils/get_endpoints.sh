USER=$1
PROJECT=$2
REQUEST_HEAD='
    {
        "auth": {
            "identity": {
                "methods": [
                    "password"
                ],
                "password": {
                    "user": {
                        "domain": {
                            "name": "Default"
                        },
                        "name": '
REQUEST_MIDDLE='
                        "password": "devstack"
                    }
                }
            },
            "scope": {
                "project": {
                    "domain": {
                        "name": "Default"
                    },
                    "name": '
REQUEST_TAIL='
                }
            }
        }
   }'
REQUEST="$REQUEST_HEAD \"$USER\", $REQUEST_MIDDLE \"$PROJECT\" $REQUEST_TAIL"
curl -s -X POST http://localhost/identity/v3/auth/tokens \
    -H "Content-type: application/json" \
    -d "$REQUEST" | jq -r .token.catalog
