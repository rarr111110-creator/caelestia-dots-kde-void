<div align="center">

<img src="assets/caelestia.svg" width="64" alt="Caelestia logo" />

# C A E L E S T I A

<h3>A KDE Plasma port of the caelestia shell</h3>


### !Este es un fork personal para adaptar el repositorio "caelestia-dots-kde" a void linux doy creditos al creador original ladybug-me.

### IMPORTANTE funciona a medias 


[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793d1?logo=arch-linux&logoColor=white&style=flat-square)](https://archlinux.org)
[![Fedora](https://img.shields.io/badge/Fedora-51A2DA?logo=fedora&logoColor=white&style=flat-square)](https://fedoraproject.org)
[![Debian](https://img.shields.io/badge/Debian-A81D33?logo=debian&logoColor=white&style=flat-square)](https://debian.org)
[![Void Linux](https://img.shields.io/badge/Void_Linux-478061?logo=void-linux&logoColor=white&style=flat-square)](https://voidlinux.org)
[![KDE Plasma](https://img.shields.io/badge/Plasma_6-1D99F3?logo=kde&logoColor=white&style=flat-square)](https://kde.org/plasma-desktop)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-86dbce?style=flat-square)](LICENSE)
[![Crowdin](https://badges.crowdin.net/caelestia-kde/localized.svg)](https://crowdin.com/project/caelestia-kde)

</div>

---

## About

A community port of the [Caelestia Hyprland dotfiles](https://github.com/caelestia-dots/caelestia) to **KDE Plasma 6**, bringing the ethereal caelestia aesthetic to a full desktop environment with broader hardware and software compatibility.

## Installation

**Requirements:** Arch-based distro, Fedora, Debian/Ubuntu or **Void Linux** (glibc or musl) · KDE Plasma 6.0+

```bash
curl -fsSL https://raw.githubusercontent.com/rarr111110-creator/caelestia-dots-kde-void/main/install.sh | sh
```

### Void Linux notes

Void Linux is supported with its own package set (**XBPS**) and init system (**runit**):

- Packages are installed with `sudo xbps-install` (no pacman/dnf/apt anywhere on Void paths).
- There is no systemd: user daemons (`cliphist`, `ydotoold`, `kde-material-you-colors`) are
  started via XDG autostart entries under `~/.config/autostart/` instead of
  `systemctl --user` units.
- A few packages not available in the Void repositories are built from source during
  installation: `ydotool`, `libcava`, `app2unit`, `Darkly`, and `caelestia-cli`.
  The `adw-gtk3` theme is fetched from its upstream release tarball.
- On Void **musl** the prebuilt installer binary is skipped automatically (it is a glibc
  build) and the installer UI is compiled locally instead.
- Session/power management works through **elogind** (present on Void KDE installs);
  suspend/poweroff buttons in the shell talk to logind over D-Bus, so no systemd is needed.
- PipeWire/WirePlumber are expected to be set up the standard Void way (XDG autostart,
  see the Void handbook) — the installer does not manage system audio services.
- Void's `quickshell` package tracks stable releases, not git master. If the shell
  reports missing QML features after updating, build quickshell from source.
- Ollama is optional; on Void a native runit service is registered at `/etc/sv/ollama`
  and enabled via `/var/service`.

If you install manually on Void, the minimum requirements are:

```bash
sudo xbps-install -Sy git curl
git clone https://github.com/rarr111110-creator/caelestia-dots-kde-void.git ~/caelestia-dots-kde
cd ~/caelestia-dots-kde && bash scripts/setup.sh
```

### Updating

- **Installer TUI:** run the installer and choose *Update*
- **GUI:** Shell Settings -> Updates -> select branch -> Install Updates
- **CLI:** `bash update.sh` and choose `main` (stable) or `dev` (bleeding edge)

Shell settings are preserved across updates.

### Uninstalling

Choose *Uninstall* from the installer TUI, or run:

```bash
bash ./uninstall.sh
```

## Screenshots

<!-- markdownlint-disable-next-line MD034 -- a bare URL is what GitHub turns into an inline video player -->
https://github.com/user-attachments/assets/4c3e20c9-5050-4cc8-8e9c-32fd0594ac8b

| Shell | Lockscreen |
| :---: | :---: |
| <img width="460" alt="shell" src="assets/shell-screenshot.png" /> | <img width="460" alt="lockscreen" src="assets/lockscreen-screenshot.png" /> |

## Keybinds

| Shortcut | Action |
| --- | --- |
| `Super` | App launcher |
| `Super + /` | Keybind cheatsheet |
| `Super + Enter` | Terminal |
| `Super + Tab` | Overview |
| `Super + 1–5` | Switch workspace |
| `Super + B` | Notification sidebar |
| `Super + V` | Clipboard history |
| `Super + Shift + S` | Screenshot |
| `Super + Shift + A` | Google Lens |
| `Super + Shift + D` | Text recognition |
| `Super + Ctrl + S` | Screen recorder |
| `Super + Shift + C` | Color picker |
| `Super + Shift + V` | Emoji selector |

## Customization

<details>
<summary><b>Wallpaper & colors</b></summary>

Use the built-in wallpaper manager (`Super`, then `>Wallpaper`). Dynamic color schemes update automatically with your wallpaper. Do **not** use the default KDE wallpaper manager.

To browse all settings, `Super`, then `>Settings` to launch the Caelestia Settings - navigate to **Appearance** for wallpaper, colors, and themes.

</details>

<details>
<summary><b>Keyboard shortcuts</b></summary>

Use the built-in keyboard shortcut manager present in Caelestia Settings.

</details>

<details>
<summary><b>Greeter animations</b></summary>

Replace `morning.gif`, `afternoon.gif`, `evening.gif`, and `night.gif` in `~/.config/quickshell/caelestia/assets/`. Then restart the shell through Quick toggles panel.

</details>

<details>
<summary><b>Plugin Store</b></summary>

Head to Caelestia Settings -> Plugins -> Store to browse for available plugins and customize your shell the way you like.

</details>

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Widgets not appearing | Log out and back in, or run `caelestia shell -d` |
| Colors not applying | systemd distros: `systemctl status --user kde-material-you-colors.service`. Void/runit: check `pgrep -af kde-material-you-colors` (it autostarts via `~/.config/autostart/kde-material-you-colors.desktop`) |
| Install failed mid-way | Re-run `bash ./scripts/setup.sh` |
| Full reset needed | See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |

For detailed debug logs, enable Debug Mode in Nexus -> About -> Advanced, then run `caelestia shell -l`.

## Thanks to

<!-- contributors-start -->
<table><tr>
<td width="50%">

### PRs

| Contributor | PRs |
| --- | ---: |
| [WinTone01](https://github.com/WinTone01) | 60 |
| [aroaxinping](https://github.com/aroaxinping) | 6 |
| [Vinax89](https://github.com/Vinax89) | 5 |
| [jialfaro](https://github.com/jialfaro) | 2 |
| [SalihYzts](https://github.com/SalihYzts) | 2 |
| [0x0nYx](https://github.com/0x0nYx) | 1 |
| [tomjod](https://github.com/tomjod) | 1 |
| [Peace-W](https://github.com/Peace-W) | 1 |

</td>
<td width="50%">

### Issues

| Contributor | Issues |
| --- | ---: |
| [0x0nYx](https://github.com/0x0nYx) | 156 |
| [Kyedae](https://github.com/Kyedae) | 17 |
| [bubbleo0](https://github.com/bubbleo0) | 12 |
| [RaceConditionWinner](https://github.com/RaceConditionWinner) | 10 |
| [KhanhNguyen1603](https://github.com/KhanhNguyen1603) | 9 |
| [francisco-tato](https://github.com/francisco-tato) | 7 |
| [arceus4526](https://github.com/arceus4526) | 6 |
| [RealNath](https://github.com/RealNath) | 6 |

</td>
</tr></table>

<!-- contributors-end -->

## Star History

<a href="https://www.star-history.com/?repos=ladybug-me%2Fcaelestia-dots-kde&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=ladybug-me/caelestia-dots-kde&type=date&theme=dark&legend=top-left&sealed_token=NFI4jXcoZAI26MlGX2jEasHMRd1PIS09clm_CVDS7SFGajH3wiHlN72P8WzuOQT2k2F71ZOCGl_xoy8eVpWlWtA0ACY3koK0NIS1-vLecN0vbvYgrZDN9kp8sQn7NT2xPNeilgrmzYWTzgdQYgskaDMGophAKmy6r6LUfQj8iFjy-Gunuqnte3EY14fX" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=ladybug-me/caelestia-dots-kde&type=date&legend=top-left&sealed_token=NFI4jXcoZAI26MlGX2jEasHMRd1PIS09clm_CVDS7SFGajH3wiHlN72P8WzuOQT2k2F71ZOCGl_xoy8eVpWlWtA0ACY3koK0NIS1-vLecN0vbvYgrZDN9kp8sQn7NT2xPNeilgrmzYWTzgdQYgskaDMGophAKmy6r6LUfQj8iFjy-Gunuqnte3EY14fX" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=ladybug-me/caelestia-dots-kde&type=date&legend=top-left&sealed_token=NFI4jXcoZAI26MlGX2jEasHMRd1PIS09clm_CVDS7SFGajH3wiHlN72P8WzuOQT2k2F71ZOCGl_xoy8eVpWlWtA0ACY3koK0NIS1-vLecN0vbvYgrZDN9kp8sQn7NT2xPNeilgrmzYWTzgdQYgskaDMGophAKmy6r6LUfQj8iFjy-Gunuqnte3EY14fX" />
 </picture>
</a>

## Credits

- [Caelestia](https://github.com/caelestia-dots) - original design language and dotfiles
- [ladybug-me](https://github.com/ladybug-me) - KDE port lead & maintainer
- [0xSolanaceae](https://github.com/0xSolanaceae) - maintainer
- [dim-ghub](https://github.com/dim-ghub/caelestia-shell) - v2.0.0 features
- [Bali10050](https://github.com/Bali10050/Darkly) - Darkly Qt
- [wrymt](https://github.com/wrymt/darkly-gtk) - Darkly GTK
- [Haidir](https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set) - icon set

## License

[GPLv3](../LICENSE)

---

> *“Ad astra per aspera.”*
