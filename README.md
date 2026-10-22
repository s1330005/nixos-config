# Installation Guide
 
## 1. Download NixOS
 
Download the `Minimal ISO image` from the [NixOS download page](https://nixos.org/download/).
 
## 2. Create a Live USB

1. Check the USB drive name with `lsblk`

```sh
lsblk
```
The output will look like this:
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    1  14.5G  0 disk
├─sda1        8:1    1   1.5G  0 part 
└─sda2        8:2    1     3M  0 part
nvme0n1     259:0    0 500.0G  0 disk
```
In this case, sda is the USB drive.

2. Unmount the USB
```sh
sudo umount -l /dev/sda1
sudo umount -l /dev/sda2
```

3. Write the ISO file
```sh
sudo dd if=/home/user/Downloads/xxxxx.iso of=/dev/sda bs=4M conv=fsync oflag=direct status=progress
```

4. Remove the drive when done

## 3. Install
 
Boot from the live USB and launch **NixOS Installer (Linux LTS)**.

A wired connection works out of the box. For Wi-Fi:

```sh
nmcli device wifi connect <SSID> password <password>
```
 
1. Partition the Disk
 
```sh
sudo -i          # Switch to root user
lsblk            # Check disk names
cfdisk /dev/XXX  # Replace XXX with the name of the target disk
```
 
- Select `gpt` for **Select label type**
- Select `New` → set **Partition size** to `1G` → select `Type` → set to `EFI System`
- Select `New` on free space → set **Partition size** to `4G` → select `Type` → set to `Linux filesystem` (encrypted swap; it holds a LUKS container)
- Select `New` on free space → press Enter twice to use the remaining space as the root partition (`Linux filesystem`)
- Select `Write`, type `yes`, then select `Quit`

2. Encrypt, Format and Mount

Root and swap are each a LUKS2 container (cryptsetup's default: argon2id + aes-xts-plain64).
Use the **same passphrase** for both so a single prompt at boot unlocks everything.
ZFS sits on top of the unlocked root (ZFS native encryption is not used).
Swap stays on its own partition because swap on ZFS (zvol) is not recommended.

```sh
lsblk  # Verify partitions were created correctly

cryptsetup luksFormat --type luks2 /dev/XXX3
cryptsetup luksFormat --type luks2 /dev/XXX2   # same passphrase as above
cryptsetup open /dev/XXX3 cryptroot
cryptsetup open /dev/XXX2 cryptswap

mkswap -L swap /dev/mapper/cryptswap
mkfs.fat -F 32 -n boot /dev/XXX1

zpool create -o ashift=12 \
  -O compression=zstd -O atime=off -O xattr=sa -O acltype=posixacl \
  -O mountpoint=none rpool /dev/mapper/cryptroot
zfs create -o mountpoint=legacy rpool/root
zfs create -o mountpoint=legacy rpool/nix
zfs create -o mountpoint=legacy rpool/home

mount -t zfs rpool/root /mnt
mount --mkdir -t zfs rpool/nix /mnt/nix
mount --mkdir -t zfs rpool/home /mnt/home
mount --mkdir -o umask=077 /dev/XXX1 /mnt/boot
swapon /dev/mapper/cryptswap

lsblk
```

Restore `/etc/nixos` from the restic backup on the backup SSD (see [section 5](#5-config-repo-backup-with-restic)).
Plug in the SSD and check its name with `lsblk` (e.g. `sdb1`; **not** the disk you just partitioned):

```sh
mount --mkdir /dev/YYY1 /media/nixos-ssd

nix-shell -p restic --run "restic -r /media/nixos-ssd/restic snapshots"
nix-shell -p restic --run "restic -r /media/nixos-ssd/restic restore latest --path /etc/nixos --target /mnt"
# restores to /mnt/etc/nixos. Add --host <hostname> to pick a specific machine's latest snapshot.

umount /media/nixos-ssd
```

restic asks for the repository password (set in section 5). The restored `/mnt/etc/nixos` is a
complete copy including `.git`, so the SSD can be unplugged right away.
`nixos-install` below still needs a network connection to download packages and flake inputs.

This repo defines one `nixosConfigurations` entry per machine under `hosts/<hostname>/`
(currently `laptop` = US keyboard, `desktop` = JIS keyboard). Each host directory has its
own `hardware-configuration.nix` and host-specific settings (hostname, keyboard layout), so
the same repo/branch can be pushed and pulled from both machines without one machine's disk
UUIDs or keyboard layout clobbering the other's.

To add or reinstall a machine, pick the host name that matches its keyboard (or add a new one
under `hosts/<new-name>/default.nix` following the existing examples), then generate that
host's hardware config in place of the placeholder:

```sh
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hosts/<hostname>/hardware-configuration.nix
```

Check that the generated file picked up LUKS and ZFS (no manual edits should be needed):

```sh
vim /mnt/etc/nixos/hosts/<hostname>/hardware-configuration.nix
```
```nix
# expected (UUIDs will differ)
boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/...";
boot.initrd.luks.devices."cryptswap".device = "/dev/disk/by-uuid/...";

fileSystems."/"     = { device = "rpool/root"; fsType = "zfs"; };
fileSystems."/nix"  = { device = "rpool/nix";  fsType = "zfs"; };
fileSystems."/home" = { device = "rpool/home"; fsType = "zfs"; };

swapDevices = [ { device = "/dev/mapper/cryptswap"; } ];  # a by-uuid path is fine too
```

ZFS also needs a few host-specific settings. Generate a host ID:

```sh
head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
```

and add it to `hosts/<hostname>/default.nix`:

```sh
vim /mnt/etc/nixos/hosts/<hostname>/default.nix
```
```nix
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.forceImportRoot = false;
networking.hostId = "xxxxxxxx";      # the 8 hex chars generated above, unique per machine
boot.initrd.systemd.enable = true;   # systemd initrd: reuses the passphrase for cryptswap, supports LUKS2 tokens
services.zfs.autoScrub.enable = true;
services.zfs.trim.enable = true;
```

> Keep `boot.kernelPackages = pkgs.linuxPackages;` (LTS) in `configuration.nix`.
> ZFS often lags behind the newest kernel; `linuxPackages_latest` may fail to evaluate with ZFS marked as broken.

```sh
nixos-install --flake /mnt/etc/nixos#<hostname>
```

When prompted with `New password:`, set a password for root.

```sh
nixos-enter --root /mnt -c 'passwd sam'
# Enter the password you want to set
reboot
```

## 4. Customize
```sh
niri msg outputs
```
``` 
# Set your monitor resolution, refresh rate, and scale
output "HDMI-A-1" {
    mode "3840x2160@120.000"
    scale 1.5
    position x=0 y=0
}
```

```sh
git config --global user.name "myname"
git config --global user.email "myname@gmail.com"
git add .
git commit -m "first commit"
nixos-rebuild switch --flake /etc/nixos#<hostname>
```

Back up the result (it includes this machine's `hardware-configuration.nix`) to the SSD as
described in [section 5](#5-config-repo-backup-with-restic), then `reboot`.

## 5. Config repo backup with restic

`/etc/nixos` is backed up with [restic](https://restic.net/) on its own (no git remote, no
GitHub). The restic repository lives on an external SSD formatted as plain ext4; restic itself
encrypts everything (data, file names, metadata) with the repository password. The backup includes `.git`, so the
full commit history comes back with a restore. Section 3 restores from it. All commands below
need root (`sudo -i`), since `/etc/nixos` is owned by root.

### One-time SSD setup

**`mkfs.ext4` erases the SSD.** Check the device name with `lsblk` first.

```sh
mkfs.ext4 -L nixos-ssd /dev/YYY1
mount --mkdir /dev/YYY1 /media/nixos-ssd

nix-shell -p restic --run "restic init -r /media/nixos-ssd/restic"   # asks for a repository password

umount /media/nixos-ssd
```

**Do not lose the restic password**: without it the backup cannot be read, and since it is the
only protection, make it a strong passphrase. Store it somewhere other than this machine (e.g. a password manager).

### Backup

With the SSD mounted:

```sh
mount --mkdir /dev/YYY1 /media/nixos-ssd

restic -r /media/nixos-ssd/restic backup /etc/nixos --tag nixos
restic -r /media/nixos-ssd/restic forget --keep-last 10 --keep-monthly 12 --prune   # optional: thin out old snapshots

umount /media/nixos-ssd
```

Always `umount` before unplugging. Snapshots are tagged with the
machine's hostname automatically, so both machines can share one repository.

### Restore

List snapshots, then restore. Restoring to a temporary directory first is the safe way to look
at or pick files from a backup:

```sh
restic -r /media/nixos-ssd/restic snapshots
restic -r /media/nixos-ssd/restic restore latest --path /etc/nixos --target /tmp/nixos-restore
# files are under /tmp/nixos-restore/etc/nixos
```

Restore only a single file:

```sh
restic -r /media/nixos-ssd/restic restore latest --path /etc/nixos --target /tmp/nixos-restore --include /etc/nixos/home.nix
```

Restore a whole machine from the live USB: see section 3. To overwrite the running
`/etc/nixos` in place (**local changes are lost**):

```sh
restic -r /media/nixos-ssd/restic restore latest --path /etc/nixos --target /
```

### Keeping two machines in sync

Each machine has its own `hosts/<hostname>/` directory, so `configuration.nix`/`home.nix`
changes never overwrite the other machine's hardware or keyboard settings. Back up on each
machine after changing the config. To take the other machine's changes, restore its latest
snapshot to a temporary directory and merge with git:

```sh
restic -r /media/nixos-ssd/restic restore latest --host <other-hostname> --path /etc/nixos --target /tmp/nixos-restore
cd /etc/nixos
git pull /tmp/nixos-restore/etc/nixos main     # or: git fetch + git merge
nixos-rebuild switch --flake /etc/nixos#<hostname>
```

Conflicts (if any) will usually only show up in `flake.lock`; resolve by keeping either side
and re-running `nix flake update` if needed.

The SSD is the only copy outside the two machines; consider keeping a second one
(`restic -r <second repo> copy --from-repo /media/nixos-ssd/restic`, or just run `backup`
against both).

### Moving an already-installed machine onto this host layout

If a machine was already running NixOS before `hosts/<hostname>/` existed, it already has its
own working `hardware-configuration.nix` (possibly hand-edited, e.g. its filesystem and LUKS
entries). Preserve that file instead of regenerating it. With the SSD mounted:

```sh
cd /etc/nixos
cp hardware-configuration.nix /tmp/hardware-configuration.nix.bak   # back up the real one first
restic -r /media/nixos-ssd/restic restore latest --path /etc/nixos --target /tmp/nixos-restore
git fetch /tmp/nixos-restore/etc/nixos main
git reset --hard FETCH_HEAD           # adopt the new repo layout
cp /tmp/hardware-configuration.nix.bak hosts/<hostname>/hardware-configuration.nix
nixos-rebuild switch --flake /etc/nixos#<hostname>
git add hosts/<hostname>/hardware-configuration.nix
git commit -m "Add hardware config for <hostname>"
restic -r /media/nixos-ssd/restic backup /etc/nixos --tag nixos
```

Only fall back to `nixos-generate-config --show-hardware-config` if that machine never had a
`hardware-configuration.nix` of its own (e.g. a brand-new install).

## 6. ZFS basics

Datasets created in step 3: `rpool/root` (`/`), `rpool/nix` (`/nix`), `rpool/home` (`/home`).
All commands below need root (`sudo`).

### Status and space

```sh
zpool status                 # pool health, errors, last scrub result
zpool list                   # pool size / free space
zfs list                     # datasets and their usage
zfs list -t snapshot         # all snapshots
zfs get compressratio rpool  # how much zstd is saving
```

### Snapshots

A snapshot is an instant, read-only copy of a dataset. It costs no space at first and only
grows as the live data changes.

```sh
# create (name after @ is free-form)
zfs snapshot rpool/home@before-cleanup
zfs snapshot -r rpool@2026-10-04          # every dataset in the pool at once

# list
zfs list -t snapshot -o name,used,creation

# delete
zfs destroy rpool/home@before-cleanup
zfs destroy -r rpool@2026-10-04
```

### Restoring

Restore a single file by copying it out of the hidden `.zfs` directory at the dataset root:

```sh
ls /home/.zfs/snapshot/before-cleanup/sam/
cp /home/.zfs/snapshot/before-cleanup/sam/notes.txt /home/sam/
```

Roll the whole dataset back to a snapshot (**everything changed after it is lost**):

```sh
zfs rollback rpool/home@before-cleanup
# if newer snapshots exist, -r is required and destroys them too
zfs rollback -r rpool/home@before-cleanup
```

Rolling back `rpool/root` while it is the running system is not safe; do it from the live USB
(`cryptsetup open /dev/XXX3 cryptroot && zpool import -N rpool`, then `zfs rollback ...`).
For broken system *configuration*, picking an older generation in the boot menu is usually
enough — no rollback needed.

### Automatic snapshots

Add to `hosts/<hostname>/default.nix` (or `configuration.nix` for both machines):

```nix
services.zfs.autoSnapshot = {
  enable = true;
  frequent = 4;   # every 15 min, keep 4
  hourly = 24;
  daily = 7;
  weekly = 4;
  monthly = 12;
};
```

Choose which datasets get snapshotted with a property (the Nix store can always be rebuilt,
so skip it):

```sh
zfs set com.sun:auto-snapshot=true  rpool/root
zfs set com.sun:auto-snapshot=true  rpool/home
zfs set com.sun:auto-snapshot=false rpool/nix
```

### Backups with send / receive

Snapshots live on the same disk, so they are not a backup on their own. Copy them to another
ZFS pool (external disk or another machine):

```sh
# first full copy
zfs send rpool/home@2026-10-04 | zfs receive backup/home
# later: send only the changes between two snapshots
zfs send -i rpool/home@2026-10-04 rpool/home@2026-11-01 | zfs receive backup/home
# over SSH
zfs send rpool/home@2026-10-04 | ssh otherhost zfs receive backup/home
```

### Scrub

`services.zfs.autoScrub` runs a scrub periodically. To start one by hand and watch it:

```sh
zpool scrub rpool
zpool status rpool
```

With a single disk, a scrub detects corruption but cannot repair it — keep backups.
