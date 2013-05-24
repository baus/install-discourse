#!/bin/bash
curl https://raw.github.com/baus/install-discourse/master/README.md -o _includes/README.md
git add _includes/README.md
git commit -m "update README.md"
git push

