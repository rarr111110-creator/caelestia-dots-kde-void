#!/usr/bin/env python3
"""Dump every static scheme's per-mode colours as a flat JSON list.

Used by the shell's Colors page to build the Light and Dark palette lists.
Each entry is {"name", "flavour", "mode", "colours"} where colours maps
Material You role names ("primary", "surface", ...) to hex values without '#'.

The "dynamic" scheme is intentionally skipped - it follows the wallpaper and
is rendered as its own card by the shell.
"""

import json

entries = []

try:
    from caelestia.utils.scheme import Scheme, get_scheme_flavours, get_scheme_modes, get_scheme_names

    for name in get_scheme_names():
        if name == "dynamic":
            continue
        for flavour in get_scheme_flavours(name):
            for mode in get_scheme_modes(name, flavour):
                try:
                    scheme = Scheme({
                        "name": name,
                        "flavour": flavour,
                        "mode": mode,
                        "variant": "tonalspot",
                        "colours": {},
                    })
                    scheme._update_colours()
                    entries.append({
                        "name": name,
                        "flavour": flavour,
                        "mode": mode,
                        "colours": scheme.colours,
                    })
                except Exception:
                    # A mode file may be missing or malformed; skip it.
                    pass
except Exception:
    # caelestia-cli not installed, or the scheme data directory is unreadable.
    pass

print(json.dumps(entries))
