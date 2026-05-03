# Cursed Museum

Steam roguelite + idle museum — Godot 4.6.

**Genre :** roguelite autobattler + tycoon-museum incrémental
**Plateformes :** Steam (Windows + Linux + macOS + Steam Deck Verified)
**Audience cible :** roguelite/deckbuilder players, 18-35
**Statut :** pré-V1, architecture validée, contenu en backlog

> Tu es le conservateur d'un musée d'artefacts maudits. Chaque relique d'internet (un copypasta ancestral, un GIF cursed, un chat quantique) est une carte de combat. Tu pars en expédition avec 4 d'entre elles, tu drafte de nouveaux artefacts au fil du run, et tu reviens enrichir ton musée — qui te génère des ressources passives pour préparer la run suivante.

## Documents principaux

- **[`DESIGN.md`](./DESIGN.md)** — GDD complet, source de vérité pour toute décision.
- **[`AGENTS.md`](./AGENTS.md)** — instructions pour les agents IA (Codex via Symphony) qui travaillent sur le repo.
- **[`WORKFLOW.md`](./WORKFLOW.md)** — contrat Symphony : config + prompt utilisé par les agents.

## Stack

- **Engine** : Godot 4.6 stable
- **Language** : GDScript
- **Plateformes** : Windows / Linux / macOS, Steam Deck Verified
- **CI** : GitHub Actions (lint, tests gdUnit4, export Linux headless)
- **Save** : local encrypted JSON + Steam Cloud
- **Steam SDK** : GodotSteam (GDExtension) — achievements, cloud, presence
- **Analytics** : Sentry (crash) + PostHog (funnel) — opt-in

## Boucle V1 (4-5 mois)

100 artefacts → 80 reliques → 4 curateurs → roguelite expéditions (3 zones × boss) → autobattle 4v4 → musée tycoon 6 tiers → prestige.
Voir `DESIGN.md` §12 pour la roadmap, §13 pour le backlog Symphony.

## Setup dev

```bash
git clone <repo-url>
cd cursed-museum

# Ouvrir avec Godot 4.6
# Editor → Import → project.godot

# Lancer tests
godot --headless --script addons/gdUnit4/bin/gdUnit4.gd --add-only res://tests
```

Le projet Godot est initialisé dans `project.godot`. La scène de démarrage
est `res://scenes/main/Main.tscn`; les dossiers de code, données, scènes,
assets, scripts et tests suivent `DESIGN.md` §10.2.

## Lancer Symphony sur ce projet

Voir `AGENTS.md` § "Pour lancer Symphony" pour la procédure complète.

Résumé express :
1. `LINEAR_API_KEY` en variable d'environnement utilisateur Windows (déjà fait).
2. Tickets `CRSD-*` créés dans le projet Linear "Cursed Museum" (à faire — copier le backlog `DESIGN.md` §13).
3. Build Symphony : `cd ../synphony/elixir && mise install && mise exec -- mix setup && mise exec -- mix build`.
4. Lancer : `mise exec -- ./bin/symphony "C:/Users/girar/Documents/Projet IA/cursed-museum/WORKFLOW.md"`.
