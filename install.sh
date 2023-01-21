#!/bin/bash

VERIFICATION_URL="http://nodes.watergun.app/verify"
API_KEY="$1"

# verify API key
echo "Verifying API key"
status_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $API_KEY" $VERIFICATION_URL)

missing_packages=()
for package in sysstat jq curl; do
  if ! which $package >/dev/null; then
    missing_packages+=($package)
  fi
done

if [ ${#missing_packages[@]} -ne 0 ]; then
  echo "The following dependencies are missing and will be installed now: ${missing_packages[*]}"
  sudo apt-get install ${missing_packages[*]} -y
  echo "All packages are already installed"
fi

# remove existing ~/.watergun directory
rm -rf ~/.watergun

# create ~/.watergun directory and store API key
mkdir -p ~/.watergun
echo $API_KEY >~/.watergun/api_key

# download monitor.sh
echo "Downloading monitor.sh"
curl -o ~/.watergun/monitor.sh https://raw.githubusercontent.com/watergunhq/monitor.sh/main/monitor.sh

# make monitor.sh executable
chmod +x ~/.watergun/monitor.sh

# run monitor.sh
echo "Collecting stats for 10 seconds"
~/.watergun/monitor.sh

# add cron job
echo "Adding cron job"
(
  crontab -l 2>/dev/null
  echo "* * * * * ~/.watergun/monitor.sh"
) | crontab -

echo "Installation complete"
