echo "Make sure you are connected to the internet and press enter (ethernet line)"
read TMP
echo "Loading Tails1154 Linux"
echo ":: Fixing Pacman Repos"
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
echo ":: Fixing PGP Keys"
pacman-key --init
pacman-key --populate
echo ":: Fixing Install script"
chmod +rwx /usr/share/scripts/install.sh
echo ":: Starting KDE Desktop"
startx
