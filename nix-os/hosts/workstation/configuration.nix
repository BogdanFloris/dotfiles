{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.hostName = "erebor";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Bucharest";

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # ── Boot ────────────────────────────────────────────────────────────
  # STAGE 1 (install day, Secure Boot temporarily OFF): plain systemd-boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15;
  boot.loader.efi.canTouchEfiVariables = true;

  # STAGE 2 (Secure Boot): after `sbctl create-keys` + firmware in Setup
  # Mode, flip the two lines below, rebuild, `sbctl verify`, then
  # re-enable Secure Boot in the BIOS.
  #   boot.loader.systemd-boot.enable = lib.mkForce false;
  #   boot.lanzaboote = {
  #     enable = true;
  #     pkiBundle = "/var/lib/sbctl";
  #   };

  # Newest USB4/DP-tunnel and xHCI fixes land here first — this is the
  # kernel channel the EC1 campaign rides.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "nvidia-drm.fbdev=1"
  ];

  # ── Graphics: RTX 5070 (Blackwell → open modules are mandatory) ────
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # Thunderbolt/USB4 device authorization (Studio Display tunnel).
  services.hardware.bolt.enable = true;
  hardware.enableRedistributableFirmware = true;

  # ── EC1 campaign: each specialisation = a boot menu entry = one
  # controlled experiment. Cold-boot on EC1, note result, `dmesg` over
  # SSH on failure. Promote the winner into the base config above.
  specialisation = {
    ec1-hostreset.configuration = {
      # Keep the firmware-established DP tunnel instead of resetting the
      # USB4 host router during kernel boot (prime suspect for the
      # boot-time black screen on the dGPU path).
      boot.kernelParams = ["thunderbolt.host_reset=false"];
    };
    usb-quirks.configuration = {
      # For the UGREEN switcher enumeration weirdness at boot.
      boot.kernelParams = ["usbcore.autosuspend=-1"];
    };
  };

  # ── Desktop: GNOME on Wayland (load gnome_profile.dconf after stow) ─
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # ── SSH from first boot: all black-screen debugging goes through this
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.bogdan = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video" "input"];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0fES5hYNWz9a6jiqSN1wPEIaVTf4QgdW91z7SEpIxy bogdan.floris@gmail.com"
    ];
  };
  programs.zsh.enable = true;

  # ── Packages: shared CLI set + desktop apps ─────────────────────────
  environment.systemPackages =
    (import ../../packages.nix {inherit pkgs;})
    ++ (with pkgs; [
      google-chrome
      ghostty
      wl-clipboard
      sbctl # Secure Boot key management (Stage 2)
    ]);

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  system.stateVersion = "25.05";
}
