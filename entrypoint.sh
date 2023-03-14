#!/bin/sh
TIME_TO_SHUTDOWN=5
dart run /app/bin/snapshot.kernel &
/tired-proxy --port 8080 --host http://localhost:9090 --time $TIME_TO_SHUTDOWN
