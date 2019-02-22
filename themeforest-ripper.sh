#!/bin/bash

# Get your token from https://build.envato.com/api/
envato_api_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

working_directory="/tmp"

die() { echo "$*"; exit 0; }

if [ -z $1 ]; then
    die "Error: no url passed"
fi

product_id=$(echo $1 | grep -Po '[0-9]+')
if [ -z $product_id ]; then
    die "Error: wrong url passed"
fi

echo "Getting template info…"

product_info=$(curl -sH "Authorization: Bearer $envato_api_key" https://api.envato.com/v3/market/catalog/item?id=$product_id)

product_name=$(echo $product_info | ./JSON.sh -s | egrep '\["name"\]' | cut -f 2 | cut -d '"' -f 2)
if [ -z "$product_name" ]; then
    die "Error: wrong url passed, or wrong api key"
fi

echo "Product name: $product_name"

preview_frame_url=$(echo $product_info | ./JSON.sh -s | egrep '\["previews","live_site","href"\]' | cut -f 2 | cut -d '"' -f 2)
if [ -z "$preview_frame_url" ]; then
    die "Error: wrong url passed, or product doesn't have any live demo, or wrong api key"
fi

echo "Getting live demo url…"

preview_url=$(curl -s http://preview.themeforest.net/$preview_frame_url | grep -oP 'iframe class="full-screen-preview__frame" src=".*?"' | sed 's/.$//' | sed 's/iframe class="full-screen-preview__frame" src="//')
if [ -z "$preview_url" ]; then
    die "Error: can't get live demo url from iframe"
fi

domain=$(echo "$preview_url" | awk -F[/:] '{print $4}')
folder_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

echo "Downloading live demo…"
httrack "$preview_url" -O "$working_directory/$folder_name" "+*.png" "+*.gif" "+*.jpg" "+*.css" "+*.js" -c8 -j >/dev/null 2>&1

echo "Zipping files…"
cd "$working_directory/$folder_name/$domain/"
zip -r -9 "./$product_name.zip" * >/dev/null 2>&1
cd -
mv "$working_directory/$folder_name/$domain/$product_name.zip" .

echo "Cleaning…"
rm -rf "$working_directory/$folder_name"

echo "Finished! Saved to '$product_name.zip'"
exit 1
