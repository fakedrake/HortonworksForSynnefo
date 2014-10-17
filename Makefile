HORTONWORKS_ID = Hortonworks_Sandbox_2.1
VM = virtualbox
OVA = $(HORTONWORKS_ID)-$(VM).ova
URL = http://hortonassets.s3.amazonaws.com/2.1/$(VM)/$(HORTONWORKS_ID).ova
VMDK = $(HORTONWORKS_ID)-disk1.vmdk
LOOP_DEV = $(shell losetup -f)
ROOT_DIR = $(CURDIR)/root
HOME_DIR = $(CURDIR)/home
DISKS_DIR = $(CURDIR)/Disks
PARTITION_FILE = $(DISKS_DIR)/Partition2
ROOT_MAP = /dev/mapper/root
HOME_MAP = /dev/mapper/home
VIRTUAL_GROUP = vg_sandbox

$(OVA):
	wget $(URL) -O $@

$(VMDK): $(OVA)
	tar xvf $(OVA)

$(DISKS_DIR) $(ROOT_DIR) $(HOME_DIR): $(VMDK)
	mkdir $@

$(PARTITION_FILE): $(DISKS_DIR) $(VMDK)
	vdfuse -f $(VMDK) $(DISKS_DIR)

losetup: $(DISKS_DIR) $(PARTITION_FILE)
	sudo losetup -f
	sudo losetup $(LOOP_DEV) $(PARTITION_FILE)

$(ROOT_MAP): | losetup
	sudo lvm vgchange -ay $(VIRTUAL_GROUP)

mount-root: $(ROOT_MAP)
	sudo mount -o loop $(ROOT_DIR) $(ROOT_MAP)

clean:
	sudo lvm vgchange -an $(VIRTUAL_GROUP)
	sudo losetup -d $(LOOP_DEV)
	fusermount -u $(DISKS_DIR)
	rm $(MVDK)
