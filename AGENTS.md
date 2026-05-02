# AGENTS.md — Cursed Museum

> Instructions for AI coding agents (Codex via Symphony, Claude Code, or any equivalent).
> If you are an agent reading this, this is your operating manual for working on this repo.

---

## 1. Source of truth

**`DESIGN.md` is the single source of truth.** Any decision, behavior, mechanic, formula, or naming convention is decided there. If something contradicts `DESIGN.md`, `DESIGN.md` wins. If you find a contradiction inside `DESIGN.md`, do **not** decide silently — surface the conflict in the Linear ticket workpad and ask for resolution.

**Do not modify `DESIGN.md` outside of explicit `CRSD-DOC-*` tickets.** Implementation tickets must conform to the GDD; if you think the GDD is wrong, file a separate `CRSD-DOC-*` ticket.

---

## 2. Stack & conventions

| Layer | Choice |
|---|---|
| Engine | Godot 4.6 stable |
| Language | GDScript (no C# in V1) |
| Renderer | Forward+ (PC) / Forward Mobile (Steam Deck) |
| Tests | gdUnit4 |
| CI | GitHub Actions (lint + test + Linux export) |
| Save | Custom encrypted JSON + Steam Cloud |
| Steam SDK | GodotSteam GDExtension |

### 2.1 Code conventions

- **GDScript naming**:
  - Files / classes: `PascalCase` (`CardData.gd`, `BattleEngine.gd`)
  - Variables / functions: `snake_case` (`compute_slot_income`, `current_phase`)
  - Constants: `SCREAMING_SNAKE_CASE`
  - Signals: `snake_case` (`battle_finished`, `card_played`)
- **Resources are data-only.** No game logic in `Resource` classes. Logic lives in autoloads or scenes.
- **Autoloads are singletons.** Access via `EventBus.signal_x.connect(...)`, never via direct node lookup.
- **No deep node paths.** Use signals via `EventBus` to decouple modules.
- **Determinism is non-negotiable** in `BattleEngine` and `RunEngine`. Always seed via `BattleRNG` / `RunRNG` — never call `randi()` / `randf()` directly inside these systems.

### 2.2 Project layout

See `DESIGN.md` §10.2 for the complete tree.

Top-level Godot folders:
```
res://autoload/   # singletons globaux (EventBus, GameState, ...)
res://data/       # Resources data-driven (.tres files)
res://scenes/     # scènes UI/gameplay
res://assets/     # sprites, audio, anims (atlasés)
res://scripts/    # scripts non rattachés à des scènes (utilitaires)
res://tests/      # tests gdUnit4
```

### 2.3 Tests

- Every implementation ticket that adds non-trivial logic **must** add tests under `res://tests/`.
- Run locally: `godot --headless --script addons/gdUnit4/bin/gdUnit4.gd --add-only res://tests`
- Determinism tests: same seed → same output (1000 simulations) for `BattleEngine` and `RunEngine`.
- Ticket validation must run before pushing. CI re-runs everything on PR.

### 2.4 Save format & versioning

- Save file is JSON, encrypted with key derived from Steam ID (fallback: machine GUID).
- `version` field at root. Bump it any time you change schema; add a migration handler in `SaveSystem.gd`.
- Atomic writes: write to `*.tmp`, fsync, rename. Never overwrite the live save directly.
- Steam Cloud sync: pull at boot, push after every save. Conflict resolution = last-write-wins for V1.

---

## 3. Non-negotiable design rules

These come from `DESIGN.md` §3.2. **Violating one of these is a blocker** — flag it in the workpad before implementing.

1. **No idle progression during a run.** `MuseumIdleClock` MUST be paused while `RunState` is non-null.
2. **Idle never trivializes runs.** Meta unlocks expand variety, not run-time stats. No buff in a run is sourced from offline time.
3. **No FOMO.** No timed events that punish absence. No daily-only currencies that expire.
4. **RNG transparency.** Drop rates visible. Pity counters visible. Same seed → same result.
5. **No microtransactions.** Cursed Museum is a paid Steam game — no IAP, no Gem currency, no in-game purchases. Ever.
6. **Steam Deck first-class.** No mouse-only UI. Focus navigation must work everywhere. Lisibilité 1280×800.

---

## 4. Linear ticket workflow

This repo uses Symphony to dispatch agents based on Linear tickets. The workflow contract is in `WORKFLOW.md`. State machine (mapped to the MEM team's actual states):

```
Backlog → Todo → In Progress → In Review → Done
                       ↑                ↓ (human asks for rework)
                       └────────────────┘
```

### 4.1 Status routing

- **`Backlog`** → do not modify, wait for human to move to `Todo`.
- **`Todo`** → immediately move to `In Progress`, create `## Codex Workpad` comment, start work.
- **`In Progress`** → continue from existing workpad.
- **`In Review`** → do nothing, wait. The human reviews the PR and either moves to `Done` (merge) or back to `Todo` with comments for rework.
- **`Done`** → terminal, shut down.
- **`Canceled` / `Duplicate`** → terminal, shut down.

When you complete implementation (branch pushed, PR opened, CI green), move the ticket from `In Progress` to `In Review`. **Do not merge yourself.**

### 4.2 Workpad

A single comment named `## Codex Workpad` is your live source of truth for the ticket. Update it as work progresses. Template:

````markdown
## Codex Workpad

```text
<hostname>:<abs-path>@<short-sha>
```

### Plan
- [ ] 1. Parent task
  - [ ] 1.1 Child task
- [ ] 2. ...

### Acceptance Criteria
- [ ] Criterion mirroring DESIGN.md spec
- [ ] Tests written and passing

### Validation
- [ ] gdUnit4: `godot --headless --script addons/gdUnit4/bin/gdUnit4.gd --add-only res://tests/<scope>`
- [ ] Manual: `godot . --debug` and verify <flow>

### Notes
- <progress note>

### Confusions
- <only when something was unclear>
````

### 4.3 Implementation discipline

- **Reproduce first** (when fixing a bug): confirm current behavior before changing code.
- **Reference DESIGN.md sections** in your commit messages (e.g., `CRSD-033: implement income formula (DESIGN.md §8.3)`).
- **Out-of-scope finds** → file a new `Backlog` ticket linked as `related`, do not expand current scope.
- **Temporary proof edits** allowed locally for verification; revert before commit.

### 4.4 PR requirements

- Branch name: `<ticket-id>-<short-slug>` e.g. `crsd-033-slot-income`.
- PR title: `[CRSD-XXX] <title>`.
- PR body: short summary + Test plan section + link to ticket.
- PR label: `symphony`.
- All checks green before moving to `Human Review`.

---

## 5. Common gotchas (project-specific)

- **`MuseumIdleClock.pause()` on `RunEngine.start_run()`** : if you forget this, the game silently violates the "no idle in run" rule. Add a test that asserts `Essence` doesn't tick during a run.
- **`Aspect` enum order matters** for the matchup graph (`Chaos > Sigma > Galaxy Brain > Cursed > Void > Chaos`). Don't reorder values without updating the matchup table.
- **Resource paths** : `.tres` files reference each other by `res://` path. Renaming a card breaks every save that references it. Use `id: StringName` as the stable identifier in code, never the file path.
- **GodotSteam init** : `SteamBridge.gd` must call `Steam.steamInit()` exactly once at boot. If Steam isn't running, fall back gracefully (offline mode) — the game must launch without Steam.
- **Determinism breaks easily** : any unsynced `Time.get_unix_time_from_system()`, `OS.get_unique_id()`, or `randi()` outside the seeded RNG breaks replay. Audit any code that touches RNG.
- **Steam Cloud quotas** : 100 MB max per game by default, but a single save should stay < 1 MB. Don't dump verbose logs to the cloud.

---

## 6. Pour lancer Symphony (instructions humain)

> Cette section est pour le dev humain superviseur, pas l'agent. Elle décrit comment dispatcher les tickets aux agents.

### 6.1 Prérequis Windows

| Outil | Pourquoi | Installation |
|---|---|---|
| **Linear** (compte + projet) | Source des tickets | linear.app |
| **Linear API Key** | Auth Symphony → Linear | Linear → Settings → Security & access → Personal API keys |
| **Codex CLI** | L'agent qui code | `npm install -g @openai/codex-cli` (OpenAI account requis) |
| **Git** | Workspace clone, commits | git-scm.com |
| **mise** (recommandé) ou Elixir 1.19 + Erlang OTP 28 | Runtime Symphony | mise.jdx.dev (utilise WSL ou Git Bash) |
| **GitHub repo** | Pour cloner le code dans les workspaces | github.com (pousser ce dossier) |

### 6.2 Étapes one-time

1. **Pousser le repo sur GitHub.** Symphony clone le repo dans chaque workspace via `hooks.after_create`.

   ```powershell
   cd "C:\Users\girar\Documents\Projet IA\cursed-museum"
   git init
   git add .
   git commit -m "Initial commit: Cursed Museum GDD v3"
   gh repo create cursed-museum --private --source=. --push
   ```

   (Remplace `gh repo create` par création manuelle GitHub + `git remote add origin ...` si tu n'as pas le `gh` CLI.)

2. **Mettre l'URL du remote dans `WORKFLOW.md`** : ouvre `WORKFLOW.md`, remplace la ligne `git clone --depth 1 <REPO_URL> .` par ton URL réelle (ex : `git@github.com:girardin/cursed-museum.git`).

3. **Mettre le project slug Linear dans `WORKFLOW.md`** : ligne `project_slug: "<PROJECT_SLUG>"`. Tu trouves le slug en faisant clic-droit → Copy URL sur ton projet "Cursed Museum" dans Linear, le slug est dans l'URL.

4. **Variable d'environnement `LINEAR_API_KEY`** : déjà fait. Vérifie avec :

   ```powershell
   echo $env:LINEAR_API_KEY
   ```

5. **Créer les tickets Linear depuis `DESIGN.md` §13.** Chaque épic = un epic Linear, chaque ticket `CRSD-XXX` = un issue. Tu peux faire ça à la main ou demander à un agent (Codex / Claude) de te générer un script qui crée les tickets via l'API Linear. Le team key par défaut configuré ici est `CRSD` — si ton team key Linear est différent, change-le dans tous les fichiers ou crée une équipe `CRSD` dans Linear.

6. **Build Symphony** :

   ```bash
   cd "C:/Users/girar/Documents/Projet IA/synphony/elixir"
   mise trust
   mise install
   mise exec -- mix setup
   mise exec -- mix build
   ```

   (Sur Windows, lance ces commandes dans Git Bash ou WSL — pas dans PowerShell. Mise et Elixir tournent mieux en environnement POSIX.)

7. **Lancer Symphony pointé sur ce projet** :

   ```bash
   cd "C:/Users/girar/Documents/Projet IA/synphony/elixir"
   mise exec -- ./bin/symphony "C:/Users/girar/Documents/Projet IA/cursed-museum/WORKFLOW.md"
   ```

   Symphony :
   - Lit `WORKFLOW.md` à ce path
   - Poll Linear toutes les 5 secondes pour les tickets `Todo` / `In Progress`
   - Crée un workspace par ticket sous `~/code/cursed-museum-workspaces/<TICKET-ID>/`
   - Clone le repo dans le workspace
   - Lance Codex en app-server mode dans le workspace
   - Codex lit le prompt de `WORKFLOW.md` (le corps Markdown), comprend le ticket, code, push, ouvre une PR
   - Le ticket passe `Todo` → `In Progress` → `Human Review` (toi, tu valides) → `Merging` → `Done`

### 6.3 Vérifier que ça marche

Avant de lancer le service complet, valide chaque dépendance individuellement :

```bash
# 1. Linear API key valide ?
curl -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_KEY" \
  -d '{"query":"{ viewer { id name email } }"}'
# Doit retourner ton compte Linear.

# 2. Codex CLI installé ?
codex --version

# 3. Mise et Elixir installés ?
mise --version
mise exec -- elixir --version

# 4. Git configuré ?
git config user.name
git config user.email
```

Si une de ces commandes échoue, installe l'outil manquant avant de lancer Symphony.

### 6.4 Debugging

- Logs Symphony : `synphony/elixir/log/`
- Workspace par ticket : `~/code/cursed-museum-workspaces/<TICKET-ID>/`
- Dashboard Phoenix optionnel : ajoute `--port 4000` à la commande `./bin/symphony` puis ouvre `http://localhost:4000`

---

## 7. Related skills

Symphony attend que les skills suivants soient disponibles côté Codex (copier depuis `synphony/.codex/skills/` vers `cursed-museum/.codex/skills/` une fois le projet sur GitHub) :

- `linear` — interagir avec Linear (commenter, mettre à jour status)
- `commit` — commits propres et logiques pendant l'implémentation
- `push` — push branche distante
- `pull` — sync avec `origin/main`
- `land` — flow de merge quand un ticket atteint `Merging`

Si ces skills ne sont pas configurés, l'agent peut quand même travailler mais ne pourra pas :
- Mettre à jour le ticket Linear automatiquement (il faudra que tu le fasses à la main)
- Auto-merger les PRs

---

**Fin du document.**
