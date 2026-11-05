# Lantern Hollow

Lantern Hollow is a spooky 3D wave-defense game for kids. You hold the last lantern in a cartoon graveyard, pop goofy zombies, build candy-powered traps, and spend coins on Hollow Street between rounds.

Made with Godot 4.7.2. No login. Keyboard and mouse.

## Play in browser

[Play Lantern Hollow](https://nolenm93.github.io/game/)

Open that link in a desktop browser. Click once to start sound, then click again on the title card when you are ready.

## Controls

- **WASD**: walk
- **Mouse**: look around
- **Left click**: shoot
- **V**: swing your bat
- **Tab**: build traps
- **1-9**: hotbar
- **R**: reload
- **E**: buy, inventory, or use town machines
- **Enter**: call the next wave
- **F**: first-person view
- **Scroll**: zoom
- **H**: open the help card
- **Esc**: pause / close cards

A short help card appears at the start. Click it or press Enter to dismiss it. Press **H** any time to read it again.

## How to build

Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (the version in `project.godot`) plus the matching export templates.

### Web

1. Open this folder in Godot.
2. Choose **Project > Export**.
3. Select the **Web** preset.
4. Export to `build/web/index.html`.

The Web preset is **non-threaded**, so it runs on GitHub Pages without COOP or COEP headers. It uses the Compatibility renderer (`gl_compatibility`) through the `rendering_method.web` override. Desktop still uses Forward+.

Serve the folder with any static server, for example:

```bash
python3 -m http.server 8080 --directory build/web
```

Then open `http://localhost:8080/`.

### Windows

Export the **Windows Desktop** preset, or run `play.bat` if you keep a local Godot editor under `tools/godot/`.

### GitHub Pages

Push to `main` (or run the **Deploy Web** workflow by hand). GitHub Actions installs Godot 4.7.2, exports the web build, and deploys it with `actions/upload-pages-artifact` and `actions/deploy-pages`.

The Pages source must be **GitHub Actions**. If the site 404s after the first green deploy, set that in the repo: **Settings > Pages > Source > GitHub Actions**.
