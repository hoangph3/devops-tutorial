# install vagrant kvm
sudo apt install vagrant
sudo apt install qemu qemu-kvm libvirt-clients libvirt-daemon-system virtinst bridge-utils

# enable service
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

# set permissions
sudo usermod -aG kvm $USER 
sudo usermod -aG libvirt $USER
sudo setfacl -m user:$USER:rw /var/run/libvirt/libvirt-sock
