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

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "nvidia-drm.fbdev=1"
  ];

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  services.hardware.bolt.enable = true;
  hardware.enableRedistributableFirmware = true;

  specialisation = {
    ec1-hostreset.configuration = {
      boot.kernelParams = ["thunderbolt.host_reset=false"];
    };
    usb-quirks.configuration = {
      boot.kernelParams = ["usbcore.autosuspend=-1"];
    };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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

  environment.systemPackages =
    (import ../../packages.nix {inherit pkgs;})
    ++ (with pkgs; [
      google-chrome
      ghostty
      wl-clipboard
      sbctl
    ]);

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  system.stateVersion = "25.05";
}
