#!/bin/bash
cd /apps/production/splitdine2_admin
export PATH="/root/.nvm/versions/node/v22.17.0/bin:$PATH"
export PORT=3011
export HOST=0.0.0.0
npm start