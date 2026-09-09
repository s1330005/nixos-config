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
sudo dd if=/home/user/Downloads/xxxxx.iso of=/dev/sda bs=4M status=progress conv=fsync
```

4. Remove the drive when done

## 3. Install
 
Boot from the live USB and launch **NixOS Installer (Linux LTS)**.
 
1. Partition the Disk
 
```sh
sudo -i          # Switch to root user
lsblk            # Check disk names
cfdisk /dev/XXX  # Replace XXX with the name of the target disk
```
 
- Select `gpt` for **Select label type**
- Select `New` → set **Partition size** to `1G` → select `Type` → set to `EFI System`
- Select `New` on free space → set **Partition size** to `4G` → select `Type` → set to `Linux swap`
- Select `New` on free space → press Enter twice to use the remaining space as the root partition
- Select `Write`, type `yes`, then select `Quit`

2. Format and Mount
 
```sh
lsblk  # Verify partitions were created correctly

mkfs.btrfs -L nixos /dev/XXX3
mkswap -L swap /dev/XXX2
mkfs.fat -F 32 -n boot /dev/XXX1
 
mount /dev/XXX3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o subvol=@,compress=zstd,noatime /dev/XXX3 /mnt
mount --mkdir -o subvol=@home,compress=zstd,noatime /dev/XXX3 /mnt/home
mount --mkdir /dev/XXX1 /mnt/boot
swapon /dev/XXX2

lsblk

git clone https://github.com/ice198/nixos.git /mnt/etc/nixos
```

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

```sh
vim /mnt/etc/nixos/hosts/<hostname>/hardware-configuration.nix
```
```nix
# add options
fileSystems."/" =
  { device = "/dev/disk/by-uuid/f081324c-3153-48e7-8896-cdbbfa8e6ea2";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

fileSystems."/home" =
  { device = "/dev/disk/by-uuid/f081324c-3153-48e7-8896-cdbbfa8e6ea2";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
```
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
reboot
```

## 5. Keeping two machines in sync

Both machines can push/pull the same repo/branch. Since each machine has its own
`hosts/<hostname>/` directory, normal changes to `configuration.nix`/`home.nix` etc. never
conflict with the other machine's hardware or keyboard settings. Workflow on each machine:

```sh
cd /etc/nixos
git pull --rebase        # get the other machine's changes first
# ... edit ...
git add -A
git commit -m "..."
git push
nixos-rebuild switch --flake /etc/nixos#<hostname>
```

If `git push` is rejected because the other machine pushed first, `git pull --rebase` and
push again. Conflicts (if any) will usually only show up in `flake.lock`; resolve by keeping
either side and re-running `nix flake update` if needed.

### Moving an already-installed machine onto this host layout

If a machine was already running NixOS before `hosts/<hostname>/` existed, it already has its
own working `hardware-configuration.nix` (possibly hand-edited, e.g. the btrfs subvolume
options from step 3 above). Preserve that file instead of regenerating it:

```sh
cd /etc/nixos
cp hardware-configuration.nix /tmp/hardware-configuration.nix.bak   # back up the real one first
git fetch origin
git reset --hard origin/main          # adopt the new repo layout
cp /tmp/hardware-configuration.nix.bak hosts/<hostname>/hardware-configuration.nix
nixos-rebuild switch --flake /etc/nixos#<hostname>
git add hosts/<hostname>/hardware-configuration.nix
git commit -m "Add hardware config for <hostname>"
git push
```

Only fall back to `nixos-generate-config --show-hardware-config` if that machine never had a
`hardware-configuration.nix` of its own (e.g. a brand-new install).
