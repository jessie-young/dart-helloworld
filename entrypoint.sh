#!/bin/bash
TIME_TO_SHUTDOWN=5

/app/bin/server & /tired-proxy --port 8080 --host http://localhost:9090 --time $TIME_TO_SHUTDOWN