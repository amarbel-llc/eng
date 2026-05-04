{
  pkgs,
  pkgs-master,
  lib,
  identity,
  inputs,
  ...
}:
{
  nix.nixPath = [
    "nixpkgs=${inputs.nixpkgs}"
    "darwin-config=$HOME/.config/nix-darwin/configuration.nix"
  ];

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  # Force fish to rebuild locally. See ../../../../../lib/fish-codesign-overlay.nix
  # for context. Required so home-manager's `programs.fish` (the user's
  # interactive shell) gets a locally-signed binary instead of the broken
  # cached one — without this, terminals SIGKILL on launch.
  nixpkgs.overlays = [ (import ../../../../../lib/fish-codesign-overlay.nix) ];

  # System packages — these get the .app bundle linked into
  # /Applications/Nix Apps/ via nix-darwin's modules/system/applications.nix.
  # Home-manager packages do NOT, which is why kitty is here in addition to
  # being configured via programs.kitty in home/common.nix.
  environment.systemPackages = [
    pkgs-master.kitty
  ];

  # Enable TouchID and YubiKey PIV smart card for sudo
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    text = lib.mkAfter "auth       sufficient     pam_smartcard.so";
  };

  # Necessary for using flakes on this system.
  # impure-derivations enables __impure builds (see eng#41 / clown FDR-0001).
  # ca-derivations is a hard prerequisite of impure-derivations.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "fetch-tree"
    "ca-derivations"
    "impure-derivations"
  ];

  # sandcastle invokes /usr/bin/sandbox-exec from inside derivations; daemon
  # defaults on darwin only whitelist /System/Library, /usr/lib, /dev, /bin/sh
  # (see NixOS/nix src/libstore/globals.cc `allowedImpureHostPrefixes`).
  nix.settings.extra-allowed-impure-host-deps = [
    "/usr/bin/sandbox-exec"
  ];

  # Enable alternative shell support in nix-darwin. Pin the package to
  # pkgs-master.fish so the system-level fish (added to environment.systemPackages
  # by the nix-darwin module) matches home-manager's interactive fish — otherwise
  # the codesign overlay forces TWO local fish rebuilds: pkgs.fish (4.2.1 from
  # nixos-25.11) for the system, and pkgs-master.fish (4.6.0) for the user.
  programs.fish.enable = true;
  programs.fish.package = pkgs-master.fish;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  system.primaryUser = identity.username;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.defaults = {
    CustomUserPreferences = {
      "org.hammerspoon.Hammerspoon" = {
        MJConfigFile = "~/.config/hammerspoon/init.lua";
      };
    };

    # "com.apple.finder" = {
    #   ShowExternalHardDrivesOnDesktop = true;
    #   ShowHardDrivesOnDesktop = true;
    #   ShowMountedServersOnDesktop = true;
    #   ShowRemovableMediaOnDesktop = true;
    #   _FXSortFoldersFirst = true;
    #   # When performing a search, search the current folder by default
    #   FXDefaultSearchScope = "SCcf";
    # };

    # "com.apple.desktopservices" = {
    #   # Avoid creating .DS_Store files on network or USB volumes
    #   DSDontWriteNetworkStores = true;
    #   DSDontWriteUSBStores = true;
    # };

    # "com.apple.screensaver" = {
    #   # Require password immediately after sleep or screen saver begins
    #   askForPassword = 1;
    #   askForPasswordDelay = 0;
    # };

    # "com.apple.screencapture" = {
    #   location = "~/Downloads";
    #   type = "png";
    # };

    # "com.apple.Safari" = {
    #   # Privacy: don’t send search queries to Apple
    #   UniversalSearchEnabled = false;
    #   SuppressSearchSuggestions = true;
    #   # Press Tab to highlight each item on a web page
    #   WebKitTabToLinksPreferenceKey = true;
    #   ShowFullURLInSmartSearchField = true;
    #   # Prevent Safari from opening ‘safe’ files automatically after downloading
    #   AutoOpenSafeDownloads = false;
    #   ShowFavoritesBar = false;
    #   IncludeInternalDebugMenu = true;
    #   IncludeDevelopMenu = true;
    #   WebKitDeveloperExtrasEnabledPreferenceKey = true;
    #   WebContinuousSpellCheckingEnabled = true;
    #   WebAutomaticSpellingCorrectionEnabled = false;
    #   AutoFillFromAddressBook = false;
    #   AutoFillCreditCardData = false;
    #   AutoFillMiscellaneousForms = false;
    #   WarnAboutFraudulentWebsites = true;
    #   WebKitJavaEnabled = false;
    #   WebKitJavaScriptCanOpenWindowsAutomatically = false;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks" = true;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled" = false;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled" = false;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles" = false;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" = false;
    # };

    # "com.apple.mail" = {
    #   # Disable inline attachments (just show the icons)
    #   DisableInlineAttachmentViewing = true;
    # };

    # "com.apple.AdLib" = {
    #   allowApplePersonalizedAdvertising = false;
    # };

    # "com.apple.print.PrintingPrefs" = {
    #   # Automatically quit printer app once the print jobs complete
    #   "Quit When Finished" = true;
    # };

    # "com.apple.SoftwareUpdate" = {
    #   AutomaticCheckEnabled = true;
    #   # Check for software updates daily, not just once per week
    #   ScheduleFrequency = 1;
    #   # Download newly available updates in background
    #   AutomaticDownload = 1;
    #   # Install System data files & security updates
    #   CriticalUpdateInstall = 1;
    # };

    # "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;

    # # Prevent Photos from opening automatically when devices are plugged in
    # "com.apple.ImageCapture".disableHotPlug = true;

    # # Turn on app auto-update
    # "com.apple.commerce".AutoUpdate = true;
  };

  # system.activationScripts.postUserActivation.text = ''
  #   # Following line should allow us to avoid a logout/login cycle
  #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  # '';
}
