# CLAUDE.md — Forking CHOMPStation2

This file is for an assistant (or contributor) working on a **new downstream fork of CHOMPStation2**. CHOMPStation2 is a BYOND/DM Space Station 13 codebase whose lineage is:

```
Baystation12  →  Polaris  →  VOREStation (Virgo)  →  Yawn-wider  →  CHOMPStation2  →  <your fork>
```

Every layer in that chain pulls fixes from its upstream. To survive that, **everything fork-specific must live in a separate modular folder and every unavoidable upstream edit must be tagged with a marker comment**. This document tells you how to do that without breaking parity.

Throughout this file, `<FORK>` is a placeholder for your fork's name. Pick a short, capitalized token (e.g. `Acme`) and substitute it everywhere: folder name `modular_acme/`, marker `// AcmeEdit`, etc.

---

## 1. The two rules

1. **Prefer modular files over upstream edits.** New content (items, mobs, jobs, recipes, planets, components, datums, maps, icons, sounds, TGUI) goes in `modular_<FORK>/`, never in `code/` or `tgui/packages/`.
2. **Mark every upstream edit.** Anywhere you cannot avoid touching a file under `code/`, `tgui/`, `interface/`, `maps/`, `icons/`, `sound/`, etc., bracket the change with `// <FORK>Edit` / `// <FORK>Add` comments so the next upstream merge can find it.

If you remember nothing else, remember those two.

---

## 2. Repository layout

| Path | Purpose | Edit policy for a downstream |
|---|---|---|
| `code/` | Base DM code from the upstream chain (Bay/Polaris/Virgo/CHOMP). | Edit only when truly unavoidable; mark every change. |
| `modular_chomp/` | CHOMP's own modular folder, mirrors `code/` layout (plus `maps/`, `icons/`, `strings/`, `html/`, `virtual_reality/`, `doc/`). Read `modular_chomp/read this.txt`. | Treat as upstream too — same rules as `code/`. |
| `modular_<FORK>/` | **Your fork's folder.** Create this; mirror the layout of `modular_chomp/`. | Free hand here. |
| `tgui/` | React/TypeScript front-end. | Do not edit upstream `tgui/packages/tgui/interfaces/*` files; copy them into `modular_<FORK>/tgui/` (or rewrite). |
| `maps/` | Base/legacy maps. | **Off-limits.** Put new maps in `modular_<FORK>/maps/`. |
| `icons/`, `sound/` | Upstream art assets. | Do not edit upstream `.dmi` / `.ogg`. Add new files under `modular_<FORK>/icons/` and override `icon`/`icon_state` on the object. |
| `config/` | Server config. `config/example/` is the template. | Server-operator concern, not code. |
| `SQL/` | Schema. | Edit only with explicit need. |
| `html/changelogs/` | YAML changelog stubs that get merged into the master changelog. | One YAML per PR (see §8). |
| `tools/` | Build/lint/map tooling (mapmerge2, StrongDMM, build.bat, etc.). | Don't touch unless you know why. |
| `bin/` | Windows entry points (`build.cmd`, `server.cmd`, `tgui-*.cmd`, `test.cmd`). | Don't edit; invoke. |
| `vorestation.dme` | **The compile manifest.** Every `.dm` file in the build must be `#include`d here. | You'll append your new files here (see §4). |
| `SpacemanDMM.toml` | DM linter / language server config. | Respect its rules (see §6). |
| `.github/CONTRIBUTING.md` | Authoritative upstream policy. | Read it; this file extends it for forks. |

---

## 3. The `modular_<FORK>/` folder

Mirror the upstream folder structure exactly so any reader can map a modular file to the upstream file it extends.

```
modular_<FORK>/
├── code/
│   ├── __defines/        ← your #define overrides / additions
│   ├── _global_vars/
│   ├── _helpers/
│   ├── _onclick/
│   ├── datums/
│   │   ├── components/
│   │   ├── crafting/
│   │   └── supplypacks/
│   ├── game/
│   └── modules/          ← bulk of new gameplay code lives here
│       ├── clothing/
│       ├── mob/
│       ├── organs/
│       ├── planet/
│       └── ...
├── icons/                ← new .dmi files (never modify upstream .dmi)
├── maps/                 ← new maps, POIs, submaps, turfpacks
├── strings/              ← localized/lookup text
├── html/                 ← in-game browser assets
└── doc/                  ← fork-specific docs
```

Pattern of what goes inside a modular file:

- **Extending an existing type** — re-open the type and add procs/vars. Example (`modular_chomp/code/modules/clothing/clothing.dm`):

  ```dm
  /obj/item/clothing
      matter = list(MAT_FIBERS = 50)

  /obj/item/clothing/shoes/MouseDrop_T(mob/living/target, mob/living/user)
      ...
      return ..()
  ```

- **Defining a wholly new type** — full path, full definition. Example (`modular_chomp/code/modules/organs/robolimbs.dm`) defines new `#define`s for monitor styles, then later files reference them.

- **Adding a new component / datum / element** — drop the file under the matching subfolder (`datums/components/`, `datums/elements/lootable/`, etc.) and the rest of the codebase uses it by type path.

Never put a "kitchen sink" file with mixed concerns at the top of `modular_<FORK>/code/` — keep the upstream-mirror structure so diffing stays meaningful.

---

## 4. Wiring new files into the build (`vorestation.dme`)

DM has no auto-discovery. Every `.dm` file the compiler should see must be listed in `vorestation.dme`. CHOMP's modular includes start around line 5269 and run to the end of the BEGIN_INCLUDE block. The pattern is one line per file, Windows path separators:

```
#include "modular_chomp\code\datums\components\dry.dm"
#include "modular_chomp\code\modules\organs\robolimbs.dm"
#include "modular_chomp\maps\~turfpacks\turfpacks.dm"
```

For your fork, add a clearly-labeled section **after** the existing `modular_chomp\...` includes:

```
// BEGIN <FORK> MODULAR INCLUDES
#include "modular_<fork>\code\__defines\my_defines.dm"
#include "modular_<fork>\code\modules\myfeature\myfile.dm"
...
// END <FORK> MODULAR INCLUDES
```

Order matters when files depend on `#define`s — keep `__defines/` includes near the top of your block. The BYOND `BEGIN_INCLUDE` / `END_INCLUDE` block is auto-maintained by Dream Maker, but for cross-platform editing it is also safe to insert manually as long as you respect the comment markers.

Maps are handled by their own `_map_selection.dm` / `maps.dm` glue inside `modular_chomp/maps/~map_system/` — model new map registration on those files.

---

## 5. Edit-marker conventions

When `modular_<FORK>/` isn't enough and you must touch an upstream file, every edit gets a marker comment. Markers are how upstream merges find your changes — without them, a future `git merge upstream/master` will silently clobber your work or you'll spend hours hunting conflicts. The CHOMP convention, which you should mirror with your own tag, is:

### 5a. Block edits (multi-line, replaces or wraps upstream code)

```dm
// <FORK>Edit Start — short reason
... your changed lines ...
// <FORK>Edit End
```

Real example from `code/__defines/announce.dm:155-...`:

```dm
//CHOMPEdit Start
ANNOUNCER_VOICE_CHOMP = list(
    ...
)
//CHOMPEdit End
```

### 5b. Block additions (multi-line, brand new content inside an upstream file)

```dm
// <FORK>Add Start — short reason
... new lines ...
// <FORK>Add End
```

Real example from `code/__defines/ZAS.dm:17-146`:

```dm
// CHOMPAdd Start
#define NORTHUP (NORTH|UP)
...
// CHOMPEdit End      ← CHOMP sometimes closes an Add with "Edit End"; accept either when reading,
                     // but when writing prefer matching pairs (Add Start / Add End).
```

### 5c. Single-line edits

Inline trailing comment, no spaces required:

```dm
#define MAX_SPECIES_TRAITS 6  // <FORK>Edit — cap positives at 6 since negatives are unlimited
#define PILOT (1<<15)         // <FORK>Edit — moved next to other explo jobs
```

CHOMP examples use a variety of casings (`//CHOMPEdit`, `// CHOMPEdit`, `//ChompEDIT`). **Pick one form for your fork and stick to it** so you can grep for all of your changes in one shot. Recommended:

- `// <FORK>Edit Start` / `// <FORK>Edit End` (with the space, capitalized).
- `// <FORK>Add Start` / `// <FORK>Add End`.
- Inline: `// <FORK>Edit — reason`.

### 5d. Always explain *why*

A bare `// AcmeEdit` is much less useful than `// AcmeEdit — disabled because our greenshift overrides this announcer`. The reason is what tells the next maintainer (or upstream-merge engineer) whether the edit is still load-bearing.

### 5e. Early-porting from upstream PRs

If you cherry-pick a change from an open VOREStation or CHOMP PR, keep the original `// CHOMPEdit` / `// VOREdit` markers on that code intact. If the PR is later merged upstream and the same change arrives via merge, you'll have to clean up the duplicate markers — that's normal (CHOMP's CONTRIBUTING.md calls this out explicitly).

### 5f. Caveats

- **`SpacemanDMM` `FileAlreadyIncluded` is set to warning** in `code/__pragmas.dm` so the turfpack generator works — don't change it back to error.
- **CI dislikes comments mid-multi-line-list.** Don't insert an edit marker between the elements of a `list(...)` that spans lines; mark above or below instead.
- **Don't add markers to whitespace-only changes.** Just don't make whitespace-only changes to upstream files — they invite merge conflicts for nothing.

---

## 6. DM coding standards (enforced)

From `SpacemanDMM.toml` and `code/__odlint.dm`:

- **No relative type paths.** Always use the absolute type path (`/obj/item/clothing/shoes/jackboots`), never relative (`shoes/jackboots`). `disallow_relative_type_definitions = true`.
- **No relative proc references.** Same rule, `disallow_relative_proc_definitions = true`.
- **DreamChecker is on** via the language server. Run it before pushing.
- **Use defined constants**, not string literals — job names, faction names, channel names, access flags, sounds. Defines live under `code/__defines/`; add yours under `modular_<FORK>/code/__defines/`.
- **Avoid `usr`** outside of verb procs. Plumb `user` through proc arguments instead, or use `src`.
- **Always chain `..()`** when overriding lifecycle procs (`Initialize`, `Destroy`, `MouseDrop_T`, etc.) unless you specifically need to suppress upstream behavior.
- **Override via vars, not edits.** When a new icon, name, or description is all that's needed, subclass or re-open the type in `modular_<FORK>/` and override `icon`, `icon_state`, `name`, `desc`. Don't edit the upstream `.dm`.

### 6a. List allocation patterns

Lists in DM are reference-counted heap allocations. A `var/list/foo = list()` on an instance var allocates one fresh empty list **per instance**, even if nothing ever gets added. With hundreds or thousands of instances alive, this adds up. Two patterns matter:

- **`var/static/list/foo`** — one list shared by every instance of the type. Use when the contents are immutable and identical across instances: cause tables, presentation strings, lookup maps. Authored once, never mutated at runtime. Saves memory linearly with instance count.
  - **DM gotcha**: you cannot override the var's storage class in a subtype. If you declare `var/list/foo` on a parent and `var/static/list/foo = list(...)` on a child, DM rejects it with "duplicate definition". If the parent declares `var/static/list/foo`, that's a single global shared across all subtypes — assigning to it in a subtype overwrites the same storage. The "static per subtype" pattern just isn't expressible as a var.
  - **Per-type static via proc**: the workaround is a getter proc that each subtype overrides to return a `var/static/list/` declared *inside the proc body*. DM scopes a proc-local `static` to that proc *on that type*, so each subtype's override gets its own one-time-initialised list. Readers call `obj.get_foo()` instead of `obj.foo`. Example:

    ```dm
    /datum/medical_symptom/proc/get_patient_messages()
        return null
    /datum/medical_symptom/sharp_pain/get_patient_messages()
        var/static/list/L = list("A sharp pain stabs through your body.", "Your injury flares with pain.")
        return L
    ```

    Costs one extra proc call per read but saves a per-instance list allocation. Used for symptom messages and condition vital-effect tables.
- **Lazylists** — declare `var/list/foo` (no initializer) and access via the `LAZYADD` / `LAZYINITLIST` / `LAZYLEN` / `LAZYREMOVE` macros from `code/__defines/_lists.dm`. The list stays `null` until something is actually added, and goes back to `null` when emptied via `LAZYREMOVE`. Use when the list is per-instance, mutable, but often empty.

**Anti-pattern**: `var/list/foo = list()` on an instance var. Every instance gets its own empty list — and *every subtype override* inherits the empty default rather than `null`, which means even subtype-specific subclasses that re-declare `foo = list("x", "y")` are *still* allocating because the parent's `= list()` ran first. Drop the `= list()` and use lazylist accessors instead. Locals inside procs (`var/list/temp = list()`) are fine — those are stack-frame allocations, not per-instance.

Quick decision table:

| Use case | Pattern |
|---|---|
| Constant table shared across all instances of a type | `var/static/list/foo = list(...)` |
| Per-instance mutable, often empty | `var/list/foo` + LAZYADD/LAZYLEN |
| Per-instance mutable, always non-empty | `var/list/foo = list(...)` (rare) |
| Local working list inside a proc | `var/list/foo = list()` |

The upstream codebase isn't 100% consistent on this — many vars predate the lazylist macros — so prefer the right pattern for new fork code without auditing every upstream var you touch.

---

## 7. TGUI (front-end) rules

- The TGUI workspace is `tgui/` with Biome as the formatter/linter and Bun as the runtime; commands:
  - `npm run tgui:lint` — check.
  - `npm run tgui:fix` — auto-fix (calls `biome check --write --unsafe tgui`).
  - `bin/tgui-build.cmd` — production build.
  - `bin/tgui-dev.cmd` — dev server with hot reload.
- **All TGUI code is TypeScript with explicit types.** Untyped JS files will fail review.
- **Do not edit upstream TGUI interface files.** Small CSS/text tweaks can sometimes be argued upstream; anything larger means copying the interface file into your fork's TGUI tree and rewriting it.
- New TGUI for fork-specific UIs lives under `modular_<FORK>/` with the matching folder layout; the build pipeline picks them up via the package config (model on how `modular_chomp` is treated, if at all, by the build — for greenfield TGUI most forks just add new interface files alongside the existing ones and accept the upstream-edit marker cost).

---

## 8. Changelogs

Every user-visible PR drops one YAML file in `html/changelogs/`. Filename pattern: `<author>-<branch-or-pr>.yml`. Format (see `html/changelogs/example.yml` for the canonical list of prefixes):

```yaml
author: "yourkey"
delete-after: true
changes:
  - rscadd: "Added X feature"
  - bugfix: "Fixed Y crash"
  - balance: "Tuned Z"
  - imageadd: "New sprite for Q"
```

Valid prefixes include: `rscadd`, `rscdel`, `bugfix`, `qol`, `balance`, `soundadd`, `sounddel`, `imageadd`, `imagedel`, `maptweak`, `spellcheck`, `experiment`, `refactor`, `code_imp`, `config`, `admin`, `server`, `wip`. The merge bot rolls the YAML into the master changelog and deletes the stub.

---

## 9. Build and test workflow

Windows is the supported development OS (BYOND is Windows-first). On WSL you can usually build via Wine or by invoking the `.cmd` files from a Windows shell.

- **Full build**: `bin/build.cmd` (compiles DM, then TGUI). Output: `vorestation.dmb` + `vorestation.rsc`.
- **Run server**: `bin/server.cmd` (builds then hosts on port 1337).
- **Run unit tests**: `bin/test.cmd`. Unit tests live in `code/unit_tests/`. Add fork tests under `modular_<FORK>/code/unit_tests/` (and include them in the DME).
- **Clean**: `bin/clean.cmd`.
- **TGUI**: `bin/tgui-build.cmd`, `bin/tgui-dev.cmd`, `bin/tgui-fix.cmd`.

The linter (`SpacemanDMM`) runs as part of the build; CI on PRs runs it too. Heed every DreamChecker warning — the upstream rejects red builds.

---

## 10. Working with the upstream merge

You will periodically pull from CHOMPStation2 (and through it, VOREStation). A sane cadence:

1. `git fetch upstream && git merge upstream/master` on a dedicated branch.
2. Conflicts will almost always be in upstream files you tagged. Grep the conflict hunks for `<FORK>Edit` / `<FORK>Add` to confirm you're preserving your changes, not upstream's.
3. If upstream replaced a function you patched with a cleaner version that does the same thing, **delete your patch** and stop carrying it — that's the whole point of parity.
4. Re-run `bin/build.cmd` and `bin/test.cmd` before pushing the merge.

If you find yourself wanting to edit the same upstream file three times for one feature, stop and re-architect: either push the feature upstream (so the edit goes away) or build a hook in `modular_<FORK>/` (subtype, signal, component) that lets the rest of the feature live entirely in your fork.

---

## 11. Things not to do

- ❌ Edit anything in `maps/` (upstream maps).
- ❌ Edit upstream `.dmi` icon files. Add new ones in `modular_<FORK>/icons/` and override `icon` / `icon_state`.
- ❌ Edit upstream `tgui/packages/tgui/interfaces/*.tsx` for fork features. Copy and rewrite under your modular folder.
- ❌ Add ckey/personally-locked content (CHOMP forbids this; most forks should follow suit). If you must, gate it via config, not by hard-coded ckey checks.
- ❌ Add author shoutouts, real-person names, or in-jokes to item names, descriptions, or lore strings. NPC names are fine.
- ❌ Land merge commits in a PR. CHOMP squash-merges; many merge commits make a PR un-mergeable. Rebase or squash before opening.
- ❌ Insert comments inside multi-line `list(...)` literals — the CI parser chokes.
- ❌ Use `--no-verify`, `--force` to main, or amend a published commit without explicit reason.

---

## 12. Quick checklist before opening a PR

- [ ] New code lives under `modular_<FORK>/` wherever possible.
- [ ] Every upstream-file edit is wrapped in `// <FORK>Edit` / `// <FORK>Add` markers with a reason.
- [ ] Every new `.dm` file is `#include`d in `vorestation.dme`.
- [ ] Absolute type/proc paths only; no relative paths.
- [ ] DreamChecker (`SpacemanDMM`) passes locally.
- [ ] If TGUI changed: `npm run tgui:lint` is clean and `npm run tgui:fix` left no diff.
- [ ] One YAML changelog stub in `html/changelogs/` for the PR.
- [ ] Single commit (or squash-able). First line of commit message ≤ 72 chars.
- [ ] Title doesn't say `[WIP]` unless the PR is in draft.

---

## 13. Where to look when stuck

- **Upstream policy:** `.github/CONTRIBUTING.md` — authoritative; defer to it on conflicts with this doc.
- **CHOMP modular philosophy:** `modular_chomp/read this.txt`.
- **DM linter rules:** `SpacemanDMM.toml`, `code/__odlint.dm`, `code/__pragmas.dm`.
- **Build entry point:** `bin/build.cmd` → `tools/build/build.bat`.
- **TGUI tooling:** `package.json`, `biome.json`, `tgui/README.md`.
- **Changelog format:** `html/changelogs/example.yml`.
- **PR template:** `.github/PULL_REQUEST_TEMPLATE.md` (uses `:cl: … :/cl:` blocks for changelog).
- **Map tools:** `tools/mapmerge2/readme.md`, `tools/StrongDMM/README.md`.
- **Existing edit markers (examples to model):** grep `code/` for `CHOMPEdit Start`, `CHOMPAdd Start`, `//CHOMPEdit`, `//ChompEDIT`.

---

## TL;DR

> Put new code in `modular_<FORK>/`. Mirror the upstream folder layout. When you must touch a base file, wrap the change in `// <FORK>Edit Start` … `// <FORK>Edit End` (or `// <FORK>Add` for new content) with a brief reason. Register every new `.dm` in `vorestation.dme`. Use absolute type paths, drop a changelog YAML, and squash before merge.
