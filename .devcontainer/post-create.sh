#!/bin/bash

# this runs at Codespace creation - not part of pre-build

echo "post-create start"
echo "$(date +'%Y-%m-%d %H:%M:%S')    post-create start" >> "$HOME/status"

# secrets are not available during on-create

if [ "$PAT" != "" ]
then
    mkdir -p "$HOME/.ssh"
    echo "$PAT" > "$HOME/.ssh/akdc.pat"
    chmod 600 "$HOME/.ssh/akdc.pat"
fi

# add shared ssh key
echo "$ID_RSA" | base64 -d > "$HOME/.ssh/id_rsa"
echo "$ID_RSA_PUB" | base64 -d > "$HOME/.ssh/id_rsa.pub"

# set file mode
chmod 600 "$HOME"/.ssh/id*
chmod 600 "$HOME"/.ssh/certs.*
chmod 600 "$HOME"/.ssh/*.key

# update oh-my-zsh
git -C "$HOME/.oh-my-zsh" pull

# update repos
git -C ../webvalidate pull
git -C ../imdb-app pull
git -C ../inner-loop pull
git -C ../vtlog pull
git -C ../cli pull

# get CLI
wget -O bin/flt https://github.com/retaildevcrews/re-cli/raw/main/bin/flt
wget -O bin/kic https://github.com/retaildevcrews/re-cli/raw/main/bin/kic

chmod +x bin/flt
chmod +x bin/kic

echo "post-create complete"
echo "$(date +'%Y-%m-%d %H:%M:%S')    post-create complete" >> "$HOME/status"
