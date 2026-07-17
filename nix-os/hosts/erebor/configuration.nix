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

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 5;
  };
  boot.initrd.systemd.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

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
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  users.users.bogdan = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video" "input"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0fES5hYNWz9a6jiqSN1wPEIaVTf4QgdW91z7SEpIxy bogdan.floris@gmail.com"
    ];
  };
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  services.xremap = {
    enable = true;
    withGnome = true;
    serviceMode = "user";
    userName = "bogdan";
    config = {
      modmap = [
        {
          name = "Cmd position";
          remap = {
            leftalt = "leftmeta";
            leftmeta = "leftalt";
          };
        }
      ];
      keymap = [
        {
          name = "mac-like";
          application.not = ["com.mitchellh.ghostty"];
          remap = {
            super-c = "C-c";
            super-v = "C-v";
            super-x = "C-x";
            super-a = "C-a";
            super-z = "C-z";
            super-s = "C-s";
            super-t = "C-t";
            super-w = "C-w";
            super-f = "C-f";
            super-l = "C-l";
            super-r = "C-r";
            super-left = "home";
            super-right = "end";
            super-1 = "C-1";
            super-2 = "C-2";
            super-3 = "C-3";
            super-4 = "C-4";
            super-5 = "C-5";
            super-6 = "C-6";
            super-7 = "C-7";
            super-8 = "C-8";
            super-9 = "C-9";
            super-alt-right = "C-tab";
            super-alt-left = "C-shift-tab";
            super-shift-leftbrace = "C-shift-tab";
            super-shift-rightbrace = "C-tab";
            alt-left = "C-left";
            alt-right = "C-right";
            super-leftbrace = "alt-left";
            super-rightbrace = "alt-right";
            super-q = "alt-f4";
          };
        }
        {
          name = "terminal";
          application.only = ["com.mitchellh.ghostty"];
          remap = {
            super-c = "C-shift-c";
            super-v = "C-shift-v";
            super-t = "C-shift-t";
            super-q = "alt-f4";
          };
        }
      ];
    };
  };
  hardware.uinput.enable = true;
  users.groups.input.members = ["bogdan"];
  users.groups.uinput.members = ["bogdan"];

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
