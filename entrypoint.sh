#!/bin/sh

if [ "$ROLE" = "worker" ]; then
  echo "Starting SITO Worker..."
  ./worker
else
  echo "Starting SITO API..."
  ./api
fi
