HORTONWORKS_ID = Hortonworks_Sandbox_2.1
VM = virtualbox
OVA = $(HORTONWORKS_ID)-$(VM).ova
URL = http://hortonassets.s3.amazonaws.com/2.1/$(VM)/$(HORTONWORKS_ID).ova
VMDK = $(HORTONWORKS_ID)-disk1.vmdk
ROOT_DIR = $(CURDIR)/root
HOME_DIR = $(CURDIR)/home
DISKS_DIR = $(CURDIR)/Disks
LVM_FILE = $(DISKS_DIR)/Partition2
ROOT_MAP = /dev/mapper/root
HOME_MAP = /dev/mapper/home
VIRTUAL_GROUP = vg_sandbox
FREE_LOOP_DEV = $(shell losetup -f)
USED_LOOP_DEV = $(shell losetup -j $(LVM_FILE) | sed -n 's_^\(/dev/loop[0-9]\):.*_\1_p' | head -1)

$(OVA):
	wget $(URL) -O $@

$(VMDK): $(OVA)
	tar xvf $(OVA)

$(DISKS_DIR) $(ROOT_DIR) $(HOME_DIR): $(VMDK)
	mkdir $@

$(LVM_FILE): $(DISKS_DIR) $(VMDK)
	vdfuse -f $(VMDK) $(DISKS_DIR)



losetup: $(DISKS_DIR) $(LVM_FILE)
	sudo losetup -f
	sudo losetup $(LOOP_DEV) $(LVM_FILE)

$(ROOT_MAP): | losetup
	sudo lvm vgchange -ay $(VIRTUAL_GROUP)

mount-root: $(ROOT_MAP)
	sudo mount -o loop $(ROOT_DIR) $(ROOT_MAP)

clean:
	sudo lvm vgchange -an $(VIRTUAL_GROUP)
	[ -n '$(USED_LOOP_DEV)' ] && sudo losetup -d $(USED_LOOP_DEV) || true
	fusermount -u $(DISKS_DIR)
	rm $(MVDK)
