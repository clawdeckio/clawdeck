#!/bin/bash
cd ~/clawdeck
while true; do
  echo "[$(date)] Starting ClawDeck..."
  bin/rails server -b 0.0.0.0 -p 4001 2>&1 | tee -a /tmp/clawdeck.log
  echo "[$(date)] ClawDeck died, restarting in 3s..."
  sleep 3
done
