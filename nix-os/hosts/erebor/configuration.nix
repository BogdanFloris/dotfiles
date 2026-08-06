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
    ports = [2222];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  # Auto-bans IPs after repeated failed SSH attempts. Matters once the
  # UniFi port-forward to this port is toggled on for remote access.
  services.fail2ban.enable = true;

  # Keeps ssh.bogdanfloris.com pointed at the current home IP so the
  # UniFi port-forward target is reachable even if the ISP rotates it.
  # cloudflare-ddns-token must be created manually on this machine
  # (root:root, mode 600) with a Cloudflare API token scoped to
  # Zone:DNS:Edit on bogdanfloris.com — it is intentionally not in git.
  services.ddclient = {
    enable = true;
    protocol = "cloudflare";
    zone = "bogdanfloris.com";
    domains = ["ssh.bogdanfloris.com"];
    username = "token";
    passwordFile = "/etc/ddclient-cloudflare-token";
    ssl = true;
  };

  users.users.bogdan = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video" "input"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0fES5hYNWz9a6jiqSN1wPEIaVTf4QgdW91z7SEpIxy bogdan.floris@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAZJqaoD38LHTktXQdSnCSJiOxixqvA1+Zuu3RBLB8j google-mac"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGb/Uk4AmJNlf5C3c1ocs7DNfMCSpHlB5ZCd4OWAaqE4 google-workstation"
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
    # GNOME reserves the monitor-brightness media keys before custom shortcuts
    # can handle them. Intercept them here and invoke asdbctl directly instead.
    extraArgs = ["--allow-launch=true"];
    config = {
      modmap = [
        {
          name = "Studio Display brightness";
          remap = {
            brightnessdown = {
              skip_key_event = true;
              press.launch = ["${pkgs.asdbctl}/bin/asdbctl" "down"];
            };
            brightnessup = {
              skip_key_event = true;
              press.launch = ["${pkgs.asdbctl}/bin/asdbctl" "up"];
            };
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
            super-tab = "alt-tab";
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
  # for studio display brightness
  services.udev.packages = [pkgs.asdbctl];
  services.udev.extraRules = ''
    SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
    SUBSYSTEM=="pci", ATTR{vendor}=="0x1b21", ATTR{device}=="0x2425", ATTR{power/control}="on"
    SUBSYSTEM=="pci", ATTR{vendor}=="0x1b21", ATTR{device}=="0x2426", ATTR{power/control}="on"
  '';

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
