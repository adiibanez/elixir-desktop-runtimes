# rsync -rte "ssh -p 29388" wfrftraumqzytqkhtfv.ddns.net
EXCLUDE="--exclude=_build --exclude=.env --exclude=.elixir_ls"

rsync -rte "ssh -p 29388" $EXCLUDE $(pwd)/ sensocto.ddns.net:projects/2025_sensocto/checkouts/elixir-desktop-runtimes/
#rsync --progress -rte "ssh -p 22" $EXCLUDE $(pwd)/ 192.168.1.195:projects/2025_sensocto/checkouts/elixir-desktop-runtimes/

ssh -p 29388 sensocto.ddns.net cd projects/2025_sensocto/checkouts/elixir-desktop-runtimes/ && sh run-android.sh