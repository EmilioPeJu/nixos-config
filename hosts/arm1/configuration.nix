{ config, pkgs, lib, ... }:

let dirty = (import ../../dirty.nix { });
in {
  imports =
    [ ./../../ssh.nix ./../../notify.nix ./../../hass.nix ./../../wifi.nix ];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      # Some gui programs need this
      "cma=128M"
    ];
  };

  boot.loader.raspberryPi = {
    enable = true;
    version = 4;
  };
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "arm1";
    networkmanager.enable = false;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0 = {
      ipv4.addresses = [{
        address = "192.168.100.1";
        prefixLength = 24;
      }];
    };
    firewall.allowedTCPPorts = [ 111 2049 4045 8200 20048 ];
    firewall.allowedUDPPorts = [ 111 2049 4045 1900 20048 ];
  };

  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  # NFS server
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt 192.168.88.0/24(rw,sync,no_subtree_check)
  '';

  environment.systemPackages = with pkgs; [
    pulsemixer
    bashmount
    neovim
    automake
    binutils
    file
    flex
    gcc
    gdb
    gitAndTools.gitFull
    gnumake
    home-assistant-cli
    kernelshark
    meson
    mpd
    mpc_cli
    ncmpc
    ninja
    nmap
    oprofile
    perf-tools
    pkgconfig
    python3
    radare2
    ranger
    remind
    rustfmt
    rustup
    sloccount
    strace
    tig
    tmux
    trace-cmd
    valgrind
    yacc
    yara
    zeal
  ];

  users = {
    mutableUsers = false;
    users.root = { hashedPassword = dirty.rootHash; };
    users.user = {
      uid = 1001;
      isNormalUser = true;
      extraGroups = [ "video" "audio" ];
      hashedPassword = dirty.userHash;
    };
  };

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt" = {
      device = "/dev/sda1";
      fsType = "ext4";
      options = [ "noatime" "nofail" ];
    };
  };

  nixpkgs.config = { allowUnfree = true; };
  # I got some funny issue in which system get hung
  #powerManagement.cpuFreqGovernor = "ondemand";
  system.stateVersion = "20.09";
}