#!/bin/sh
# Deploy the landing page to thinktwice.pgf.lv (Ubuntu + nginx + certbot).
# Usage: ./deploy.sh [user@host]      default: krisjanis@pgf.lv. The user needs sudo; key login only.
set -eu
TARGET="${1:-krisjanis@pgf.lv}"
cd "$(dirname "$0")"
rsync -az --delete index.html gsap.min.js icon.png og.png poster.png video.mp4 "$TARGET:/tmp/thinktwice-site/"
scp -q thinktwice.pgf.lv.nginx "$TARGET:/tmp/"
ssh "$TARGET" 'set -eu
sudo mkdir -p /var/www/thinktwice.pgf.lv
sudo rsync -a --delete /tmp/thinktwice-site/ /var/www/thinktwice.pgf.lv/
sudo chown -R www-data:www-data /var/www/thinktwice.pgf.lv
# Install the plain site only the first time; afterwards certbot owns the HTTPS lines in it.
if [ ! -e /etc/nginx/sites-available/thinktwice.pgf.lv ]; then
  sudo install -m 644 /tmp/thinktwice.pgf.lv.nginx /etc/nginx/sites-available/thinktwice.pgf.lv
  sudo ln -sf /etc/nginx/sites-available/thinktwice.pgf.lv /etc/nginx/sites-enabled/thinktwice.pgf.lv
  sudo nginx -t && sudo systemctl reload nginx
  sudo certbot --nginx -d thinktwice.pgf.lv --non-interactive --redirect
fi
sudo nginx -t && sudo systemctl reload nginx'
curl -sI https://thinktwice.pgf.lv/ | head -1
