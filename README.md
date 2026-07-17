# dsxtool-packaging

Packaging scripts for [dsxtool](https://github.com/csouzape/dsxtool). Turns a
pile of bash scripts into something you can double-click. That's it. That's
the whole pitch.

## What this is

dsxtool is a Bash/fzf post-install automation tool for Arch, Debian, and
Fedora. It works fine as a pile of shell scripts you clone and run. Some
people, however, want to download one file and run it, without first reading
every line of source like a reasonable person. This repo exists for them.

Right now it builds an AppImage. If someone wants to add AUR, Flatpak, .deb,
whatever — fine, send a PR. Just don't expect me to maintain five packaging
formats nobody asked for.

## Structure

```
dsxtool-packaging/
├── dsxtool/                  git submodule, points at the real repo
├── appimage/
│   ├── AppDir-template/      static skeleton: AppRun, .desktop, icon
│   └── build-appimage.sh     the actual build
├── LICENSE
└── README.md
```

`dsxtool/` is a submodule, not a copy-paste. If you cloned this without
`--recurse-submodules`, that directory is empty and the build will
immediately tell you so instead of failing in some confusing way three
steps later.

## Building

```bash
git clone --recurse-submodules https://github.com/csouzape/dsxtool-packaging.git
cd dsxtool-packaging/appimage
./build-appimage.sh
```

Output lands in `appimage/dist/dsxtool-<version>-x86_64.AppImage`.

Flags, if you need them:

```
--fetch-fzf          bundle a static fzf binary instead of relying on the host's
--no-download-tool    skip fetching appimagetool (use appimage/tools/ instead)
```

Default assumes `fzf` is already installed on the host system, because it
probably is if you're running a Linux post-install tool in the first place.
Use `--fetch-fzf` if you actually need a fully self-contained image.

## Updating to a new dsxtool release

The submodule doesn't update itself. Nothing does that automatically, and
nothing should:

```bash
git submodule update --remote dsxtool
git add dsxtool
git commit -m "Bump dsxtool submodule"
```

Then rebuild.

## Requirements

- `bash`
- `curl`
- `git`
- FUSE (to actually *run* the resulting AppImage — most distros have this,
  some don't, that's not my problem to fix)

Nothing else. No Docker, no CI framework, no build system with its own
plugin ecosystem. It's a bash script that copies files into a directory and
calls `appimagetool`. If that offends your sensibilities, this is not the
repo for you.

## Known issues

- The icon in `AppDir-template/dsxtool.png` is a placeholder. If it's still
  there when you read this, nobody's gotten around to making a real one.
- No AppStream metadata yet, so `appimagetool` will nag you about it. It's
  harmless. Ignore it, or send a PR with the metainfo file if it bothers you
  that much.

## License

See `LICENSE`. Same terms apply here as they do to dsxtool itself — read it
if you care, don't if you don't.