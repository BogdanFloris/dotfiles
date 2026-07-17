# Declarative partitioning for the dedicated Linux NVMe.
#
# !! SET `device` BELOW ON INSTALL DAY !!
# Verify with `lsblk -o NAME,SIZE,MODEL` from the installer — it must be
# the old Fedora disk, NOT the Windows one. Prefer the stable path:
#   /dev/disk/by-id/nvme-<model>_<serial>
#
# Layout: 1G ESP (NixOS-owned, Windows ESP untouched) + LUKS2 holding
# btrfs subvolumes. TPM auto-unlock is enrolled in Stage 3, AFTER
# Secure Boot reaches its final state (PCR 7 depends on it).
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/CHANGE-ME";
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@swap" = {
                  mountpoint = "/.swap";
                  swap.swapfile.size = "32G";
                };
              };
            };
          };
        };
      };
    };
  };
}
