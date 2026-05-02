# Cursed Museum — GDD v3 (Steam Roguelite Edition)

> **Document principal de référence** pour Symphony et tout agent de développement travaillant sur le projet.
> Source de vérité unique. Toute décision contradictoire ailleurs est subordonnée à ce document.
>
> **Version :** 3.0 (Steam pivot — roguelite + idle museum)
> **Statut :** Pré-V1 — architecture validée, contenu en backlog
> **Audience cible technique :** agents de coding (Codex via Symphony) + dev humain superviseur

---

## 0. Résumé exécutif (TL;DR)

**Cursed Museum** est un jeu **PC Steam** construit avec **Godot 4.6**, fusionnant trois boucles qui se nourrissent l'une l'autre :

1. **Roguelite expéditions** : runs de 30-50 min sur une carte à la Slay the Spire, où une escouade de **4 cartes-artefacts** affronte des combats autobattle. Chaque run est unique (draft de cartes, draft de reliques, événements).
2. **Combat autobattle déterministe** : 7 phases, 5 types, Stagger, Elemental Surges. Le joueur n'agit pas pendant le combat — toute la décision est en pré-combat (composition, ordre, items).
3. **Musée tycoon-incrémental** (méta-hub entre runs) : tu exposes les artefacts collectés, ils génèrent **Essence** / **Fame** / **Visitors** en idle qui financent la progression méta (déblocage cartes, reliques, zones, prestige).

**Boucle macro** :

```
Run → Mort ou Victoire → Retour Musée → Idle/Upgrade → Run suivant
```

Cible session : **30-50 min par run**, 1-3 runs par session de jeu (1-3h). Idle entre les sessions = couche de progression long-terme.

**Différence clé vs concept mobile initial :** distribution **Steam (paid game, no IAP)**, public **adulte roguelite (18-35)**, contrôles **clavier-souris** + Steam Deck, paysage 16:9. Voir §1.

---

## 1. Pivot Mobile → Steam — décisions clés

Le GDD précédent (v2) visait iOS/Android 10-15 ans avec gacha + tycoon idle pur. Le passage à Steam impose un cadre roguelite + paid game qui doit être tranché avant V1.

### 1.1 Audience cible — décision

**Cible V1 : roguelite/deckbuilder players Steam, 18-35 ans.**

| Référence joueur | Pourquoi pertinent |
|---|---|
| Slay the Spire | Map de run, draft de cartes, transparence RNG |
| Balatro | Idle + run synergies, addiction "encore une run" |
| The Last Flame, He Is Coming | Autobattler + reliques, builds combinatoires |
| Tiny Rogues, Vault of the Void | Roguelite progression méta entre runs |

ESRB Teen / PEGI 12 acceptable (humour absurde mèmes/internet sans contenu choquant). **Pas de contenu enfants-first** : le pivot Steam libère les contraintes COPPA / UK Children's Code de la v2.

### 1.2 Systèmes mobiles abandonnés

- **Gacha packs avec pity / Gem currency / RevenueCat IAP** → **supprimés intégralement**. Cursed Museum est un paid game one-shot Steam (~14.99 € EA, ~19.99 € 1.0). Pas de microtransaction.
- **Hub navigable top-down 2D mobile portrait** → **menu UI horizontal Steam** (le musée reste une scène riche, mais en paysage 16:9 avec mouse interaction).
- **Validation parentale, gate enfants, certification "Kids"** → non pertinent.
- **Daily login streaks 7 jours, Bouquet du jour** → remplacés par **Daily/Weekly Challenges** (cf. §11).
- **Cloud save iCloud/Google Play** → remplacé par **Steam Cloud**.

### 1.3 Systèmes adaptés ou conservés

- **5 types et matchups (Chaos > Sigma > Galaxy Brain > Cursed > Void > Chaos)** : conservé identique. Les types sont rebrandés en "Aspects" pour coller au lore musée (Chaos Aspect, Sigma Aspect, Galaxy Brain Aspect, Cursed Aspect, Void Aspect).
- **Boucle 7 phases du combat, Stagger, Elemental Surges** : conservée, rebrandée en "Resonance Surges". Voir §6.
- **Tiers de musée (4 → 128 stands, adjacence, rooms thématiques)** : conservé comme **méta-hub idle**, ne sert plus de boucle principale. Voir §8.
- **Prestige reset partiel** : conservé, rééquilibré pour cadence Steam (premier prestige cible ~15-25h de jeu, pas 60).
- **Architecture Godot 4.6 + GDScript + Resources + déterminisme RNG** : conservée intégralement. Voir §10.
- **Asset pipeline IA (sprites cartes, environnements, FX)** : conservé. Voir §10.7.

### 1.4 Mapping de terminologie v2 → v3

| v2 (mobile gacha) | v3 (Steam roguelite) |
|---|---|
| Carte | **Artefact** (carte = artefact dans le lore musée) |
| Meme Coins (MC) | **Essence** (devise principale méta, idle musée + drops run) |
| Gems (premium) | **Supprimée** — pas d'IAP |
| Display Crystals | **Fame** (devise hard, drops boss + fusions hautes) |
| Pack ouvert | **Reliquaire** (pack acheté en Essence pour débloquer artefacts dans le pool de run) |
| Pity counter | **Garantie de Reliquaire** (artefact rare garanti tous les N reliquaires — transparence conservée) |
| Combat PvE zone | **Run / Expédition** (roguelite, multi-combat, branchant) |
| Daily challenge | **Daily Expedition** (run avec seed fixe + modifiers) |

---

## 2. Vision produit & audience

### 2.1 Pitch

> "Tu es le conservateur d'un musée d'artefacts maudits — chaque relique d'internet (un copypasta ancestral, un GIF cursed, un chat quantique) est une carte de combat. Tu pars en expédition avec 4 d'entre elles, tu drafte de nouveaux artefacts au fil du run, et tu reviens enrichir ton musée — qui te génère des ressources passives pour préparer la run suivante."

### 2.2 Proposition de valeur

- **Pour le joueur** : tension roguelite (chaque décision compte) + satisfaction de collection (chaque run agrandit le musée) + dopamine combo (synergies cartes × reliques × salles) + retour cool (idle progress en arrière-plan).
- **Pour le studio** : un seul mécanisme cœur (autobattle 7-phases) qui sert à la fois la run roguelite et le farming méta, content renouvelable par DLC/saison sans toucher au noyau.

### 2.3 Persona principale

- **Sam, 27 ans** : joue 5-10h/semaine, possède Slay the Spire (200h), Balatro (80h), Tiny Rogues (50h). Adore les builds combinatoires et la rejouabilité. Joue en sessions d'1-2h.
- **Motivations** : trouver des combos cartes×reliques inédits, débloquer toutes les Mythical artifacts, "1cc" l'ascension max.
- **Frustrations à éviter** : RNG opaque, build tué par un boss, idle qui rend les runs trivialement faciles, FOMO timed events.

### 2.4 Plateformes V1

- **Steam (Windows + Linux + macOS)** distribution principale.
- **Steam Deck Verified** comme cible explicite (Forward Mobile renderer, controls full-pad, lisibilité 1280×800).
- **Resolution cible** : 1920×1080 baseline, 1280×720 minimum, 3840×2160 supporté. Paysage 16:9 (pas de portrait).
- **Contrôles** : Souris + clavier en first-class. Manette/Steam Deck full support à parité (focus navigation, no mouse-only).

---

## 3. Piliers de design

### 3.1 Trois piliers qui se renforcent

```
                ┌─────────────────────┐
                │     RUN             │
                │  (roguelite,        │
                │  4-card squad,      │
                │  draft, map, boss)  │
                └──────────┬──────────┘
                  drops    │   débloque artefacts
            ┌──────────────┼───────────────┐
            ▼                              ▼
    ┌───────────────┐              ┌──────────────┐
    │   MUSÉE       │  alimente    │   COLLECTION │
    │   (idle méta, │  pool ────►  │  (artefacts, │
    │   Essence,    │              │  reliques,   │
    │   Fame)       │  ◄────       │  curateurs)  │
    └───────┬───────┘  finance     └──────┬───────┘
            │                             │
            └─────► Essence/Fame ◄────────┘
                 achat reliquaires + déblocages
```

Chaque pilier produit ce que les deux autres consomment. **Aucun pilier ne peut tout fournir seul.**

### 3.2 Règles produit non négociables

| Règle | Implication |
|---|---|
| **Aucune progression idle pendant un run** | Tout ce qui se passe en run vient de décisions joueur (draft, achat, événement). Le temps réel n'a aucun effet sur les stats / dégâts / loot pendant un combat ou un run actif. |
| **Idle = méta uniquement, capé** | Idle musée capé à 8h offline. Pas de FOMO timed events. Le joueur peut se déconnecter une semaine sans pénalité. |
| **Idle ne doit pas trivialiser les runs** | Les bonus méta débloquent **plus de variété** (cartes, reliques, zones) bien plus qu'ils ne **rendent les runs faciles**. Soft cap de buffs run actifs simultanés (cf. §8.6). |
| **Transparence RNG totale** | Drop rates affichés, pity visible, IA déterministe, replay possible. Aucun "silent rate". |
| **Build > paint** | Architecture des systèmes d'abord, contenu mèmes par-dessus. |
| **Lisibilité > complexité** | < 7 mots par bouton, systèmes enseignés par UI pas par texte long. |
| **Steam Deck first-class** | Navigation focus complète, pas de UI mouse-only, lisibilité 1280×800, 30fps stable minimum. |
| **Pas de paywall, pas de microtransaction** | Paid game one-shot. DLC/saisons V2+ sont des extensions de contenu, pas des unlocks pay-to-progress. |

---

## 4. Boucle de jeu

### 4.1 Boucle macro (session 1-3h)

```
[A] Lancement → Hub Musée
     │
     ▼
[B] Collecte idle (Essence + Fame accumulés offline)
     │
     ▼
[C] Méta-upgrades (déblocage cartes, achat reliquaire, prestige check)
     │
     ▼
[D] Préparation expédition
     │   - Choix Curateur (héros / passif global)
     │   - Choix deck starter (4-6 cartes)
     │   - Choix 1-2 reliques de départ
     │
     ▼
[E] RUN (30-50 min) — voir §5
     │
     ▼
[F] Run-end : victoire, défaite, ou abandon
     │   - Drops (Essence, Fame, artefacts permanents, reliques meta)
     │
     ▼
[G] Retour Musée → re-place artefacts gagnés
     │
     ▼
[H] Quit ou run suivant ([D])
```

### 4.2 Pourquoi le joueur revient

- **Variety pull** : chaque run est différent (draft, événements, RNG seedé).
- **Build curiosity** : "et si j'essayais Mono-Cursed avec la relique Echo Chamber ?"
- **Progression ladder** : ascensions/corruptions débloquent des défis croissants (cf. §11).
- **Idle catch-up** : reviens 8h plus tard, le musée a accumulé des ressources qu'il faut "vider" en achats.
- **Daily / Weekly** : 1 run challenge par jour avec seed publique (leaderboard visible §11.2).
- **Achievements Steam** : 100+ achievements (récolter X artefacts, finir Mono-type, etc.).

### 4.3 Le hub musée, ce qu'il N'EST PAS

- Le musée n'est **pas le gameplay principal**. C'est la couche méta entre les runs.
- Le hub est une scène 2D/2.5D **statique-ish** (caméra fixe ou pan léger), pas une map navigable physique.
- Pas de PNJ qui se déplacent, pas de quêtes au PNJ. Tous les services (Curateur select, Reliquaire shop, Run portal, Prestige altar, Settings) sont des **boutons UI clairs** dans le hub.
- Le **plaisir** du musée vient de : (a) regarder ses artefacts s'aligner, (b) calculer l'adjacence, (c) voir les chiffres monter en idle, (d) débloquer la nouvelle salle.

---

## 5. Spécification du Run (Roguelite)

### 5.1 Vue d'ensemble

Un run dure **30-50 minutes** et se déroule sur une **map à la Slay the Spire** : graphe orienté de nœuds, plusieurs chemins, un boss en fin de zone, plusieurs zones avant le boss final.

```
┌── Combat ── Event ── Combat ── Élite ──┐
│                                          │
Start ── Combat ── Shop ── Combat ── Repos ── Combat ── Élite ── Boss ── (zone+1)
│                                          │
└── Event ── Combat ── Repos ── Élite ───┘
```

### 5.2 Pré-run : préparation

| Étape | Choix joueur | Source |
|---|---|---|
| 1. Curateur | 1 parmi 4 (V1 : 4 curateurs débloquables) | Pool débloqué en méta |
| 2. Deck starter | Auto par curateur, 4-6 cartes | Curateur définit le deck |
| 3. Reliques de départ | 1-2 parmi 3 proposées (RNG dans le pool méta) | Pool reliques débloqué méta |
| 4. Difficulté | Niveau 0 (normal) → 20 (max ascension) | Déblocage progressif après victoire |
| 5. Mode | Standard / Daily Seed / Weekly Seed | Selon date/déblocage |

### 5.3 La map de run

- **Largeur** : 5-7 colonnes (chemins parallèles).
- **Profondeur** : 12-16 nœuds par zone, 3 zones par run.
- **Connectivité** : chaque nœud → 1-3 nœuds de la colonne suivante. Pas de retour en arrière.
- **Affichage** : map visible en permanence (icône en haut à droite ou screen dédiée, similaire StS).
- **Visibilité du nœud** : type connu en avance (combat, élite, event, shop, repos). Le contenu exact (drop, choix d'event, items du shop) reste caché jusqu'à l'arrivée.

### 5.4 Types de nœuds

| Nœud | Icône | Contenu | Probabilité base |
|---|---|---|---|
| **Combat** (mob) | ⚔️ | Combat 4v4 standard, drops Essence + chance carte | ~50% |
| **Élite** | 💀 | Combat 4v4 difficile, drops garantis (relique ou rare carte) | ~12% |
| **Event** | ❓ | Choix narratif 2-3 options, peut donner buff/malus/relique/cartes/Essence | ~15% |
| **Shop** | 🪙 | 3 cartes + 2 reliques + consommables, achat en Essence | ~10% |
| **Repos** | 🔥 | Heal 30% HP équipe **OU** upgrade 1 carte **OU** relire la map | ~10% |
| **Trésor** | 💎 | Relique gratuite, parfois avec twist | ~3% |

(Chiffres V1, à ajuster en simulation. Forcer cohérence par run : un Shop + un Repos + un Élite minimum garantis par zone.)

### 5.5 Draft post-combat

Après chaque combat gagné :

- **Combat normal** : choix de **1 parmi 3** cartes (ou skip pour +X Essence).
- **Élite** : drop garanti **1 relique** (choix 1 parmi 3).
- **Event** : variable.
- **Boss** : drop garanti **1 relique boss** (parmi un pool boss-only) + Essence + Fame + 1 artefact permanent ajouté à la collection méta.

Le draft est l'élément **clé** du roguelite. Le pool de cartes proposé est :
- Filtré par les types présents en équipe (favorise synergie) à 60%, type aléatoire à 40%.
- Pondéré par rareté selon profondeur du run.
- Jamais propose une carte déjà en main (sauf upgrade).

### 5.6 Fin de run

| Issue | Conséquences |
|---|---|
| **Victoire** (boss zone 3 vaincu) | +Fame (selon ascension), +Essence, **artefact permanent ajouté à la collection**, achievements check. |
| **Mort** | +Essence (réduit), +0 Fame, **artefact permanent ajouté** (consolation : tu gardes toujours UN artefact même en mort). |
| **Abandon volontaire** | +Essence (très réduit), +0 Fame, +0 artefact. (Évite scumming.) |

Toutes les cartes/reliques **acquises pendant le run** sont **perdues** au retour (sauf 1 artefact permanent gagné selon issue). C'est la mécanique roguelite classique : tu progresses en méta, pas en équipement run-to-run.

### 5.7 Pourquoi PAS d'idle pendant le run

**Règle non négociable** (cf. §3.2). Justifications :

- L'idle pendant un run tue la tension : "je laisse ouvert pendant que je dîne, et ça farm tout seul".
- L'idle pendant un run rend le skill RNG-dependent dans le mauvais sens : le joueur ne maîtrise pas le résultat.
- Toute la rejouabilité roguelite tient à "chaque décision compte". Une stat qui monte avec le temps n'est pas une décision.

**Implémentation** : `MuseumIdleClock.pause()` au start d'un run, `resume()` au retour hub. Aucun timer de fusion ne tourne pendant un run (les fusions sont des actions méta-hub uniquement).

---

## 6. Combat (Autobattle)

> Cette section est largement reprise du GDD v2 §5 — le moteur combat est conservé. Quelques renommages cosmétiques uniquement.

### 6.1 Vue d'ensemble

Un combat oppose **4 cartes joueur** vs **1 à 4 cartes ennemies** sur **7 phases** de durée variable, total cible **90-180s en 1×**, **45-90s en 2×**.

Le joueur n'intervient **plus pendant le combat** : toute la décision est en pré-combat (composition, ordre, items consommables avant lancement).

### 6.2 Phases du combat

| Phase | Durée | Description | Événements possibles |
|---|---:|---|---|
| 0. Intro | 3s | Caméra zoom équipes, banner zone | Aucun |
| 1. Opening | 15s | Première salve standard | Premières attaques, première lecture des types |
| 2. Build-up | 20s | Échanges normaux | Tags de Stagger qui s'accumulent |
| 3. **Resonance Surge ¹** | 5s + 25s | Surge déclenchée | Aspect dominant boost type, gameplay change |
| 4. Pivot | 25s | Reprise post-surge | Première carte tombée potentielle |
| 5. **Resonance Surge ²** | 5s + 25s | Deuxième surge (autre aspect) | Adaptation de la lecture |
| 6. Climax | 30s | Phase finale, tout-pour-tout | Ultimes, finishing blows |
| 7. Resolve | 10s | Fade out + écran résultats | Stats, MVP, drops |

### 6.3 Cinq Aspects (types) et matchups

```
Chaos > Sigma > Galaxy Brain > Cursed > Void > Chaos
```

- Avantage = **×1.5 dégâts** + tag Stagger ×1
- Désavantage = **×0.66 dégâts**
- Neutre = ×1.0
- Affichage : icône colorée + halo direction lors du hit (vert si avantage, rouge si désavantage)

### 6.4 Système Stagger

- Chaque hit super-efficace ajoute +1 stagger sur la cible
- À **3 stagger**, la cible entre en état "Staggered" pendant 5s
- Pendant Staggered : ×1.75 dégâts reçus, ne peut pas attaquer
- Animation : la carte vacille, halo blanc, son distinct
- Reset à 0 stagger après l'état terminé

### 6.5 Resonance Surges

Surges déclenchées en phase 3 et 5. Aspect aléatoire pondéré par les aspects présents en équipe (favorise les aspects absents pour relancer la lecture).

| Surge | Effet pendant 25s |
|---|---|
| Chaos Storm | +25% damage cartes Chaos, -10% défense globale |
| Cursed Tide | DoT 3%/s sur tous, soin 5%/s sur cartes Cursed |
| Galaxy Brain | +50% chance crit pour Galaxy Brain, ralentissement global 15% |
| Sigma Surge | +30% attack speed Sigma, immunité au Stagger 5s |
| Void Collapse | Drain 2%/s HP→énergie pour Void cards, dégâts true bypass armor |

### 6.6 Stats par carte (artefact)

Chaque artefact expose ces propriétés en `Resource` :

```gdscript
class_name CardData extends Resource

@export var id: StringName            # "ancient_copypasta"
@export var display_name: String      # "Ancient Copypasta"
@export var rarity: Rarity            # enum
@export var aspect: Aspect            # enum (Chaos/Cursed/GalaxyBrain/Sigma/Void)
@export_range(1, 50) var level: int = 1
@export var base_hp: int
@export var base_attack: int
@export var base_defense: int
@export var base_speed: int
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export_range(1.0, 4.0) var crit_multiplier: float = 1.5
@export var passive: PassiveEffect    # Resource
@export var ultimate: UltimateAbility # Resource
@export var portrait: Texture2D
@export var animation_set: SpriteFrames
```

### 6.7 Reliques (run-time only, sauf si gagnées en méta)

Nouveau pour v3. Une **relique** modifie le run actif :

```gdscript
class_name RelicData extends Resource

@export var id: StringName              # "echo_chamber"
@export var display_name: String        # "Echo Chamber"
@export var rarity: RelicRarity         # Common/Uncommon/Rare/Boss/Cursed
@export var description: String         # "Cursed cards trigger their passive twice."
@export var triggers: Array[RelicTrigger]  # When to fire
@export var actions: Array[EffectAction]   # What to do
@export var icon: Texture2D
```

Pool V1 : **80 reliques** (40 Common, 25 Uncommon, 10 Rare, 5 Boss).

Reliques reset à la fin du run (sauf si débloquée comme **Meta Relic** : dans ce cas elle entre dans le pool de départ proposé en pré-run).

### 6.8 Résolution déterministe

Le moteur de bataille **et le run entier** sont 100% déterministes depuis une seed donnée :

- Toutes les decisions RNG passent par un `BattleRNG` initialisé avec une seed dérivée du run ID + numéro de combat.
- L'IA ennemie suit un arbre de comportement déterministe.
- L'animation côté client peut être rejouée à partir d'une trace JSON.
- Les **Daily / Weekly seeds** sont distribuables : tout le monde joue le même run.
- **Bénéfice** : leaderboard Daily/Weekly possibles, replay, debugging facile.

### 6.9 UI/Juice combat — priorités d'implémentation

| Priorité | Effet | Implémentation Godot |
|---:|---|---|
| 1 | Hit-stop sur impact | `Engine.time_scale` 0.05 pendant 80-120ms, plus long sur Mythical/finishers |
| 2 | Damage numbers | Scene `DamagePopup`, label avec `Tween` translation+fade, couleur par type |
| 3 | Dual health bar | Custom `Control` avec 2 `ColorRect` ; ghost suit avec `Tween` 200ms delay |
| 4 | Screen shake | `Camera2D.offset` shake en `Tween`, max 10px sur PC, off avec accessibility flag |
| 5 | Audio impact | `AudioStreamPlayer` par hit avec pitch random ±10%, ducking de la musique |
| 6 | Type halo on hit | Particle `GPUParticles2D` couleur du type qui burst |
| 7 | MVP screen | Stats finales, carte MVP, "moment clé" du match |

### 6.10 Vitesse de combat

- **1×, 2×, 4× supportés** sur PC (vs mobile 1×/2× uniquement).
- Le bouton accélère les timers d'animation et raccourcit hit-stop.
- Toggle persisté dans `Settings`.
- Auto-skip option : skip directement à `Resolve` sans animation (pour farming méta plus tard).

---

## 7. Cartes / Artefacts (Collection)

### 7.1 Distribution V1 (100 artefacts)

| Rareté | Nombre | Couleur visuelle |
|---|---:|---|
| Common | 40 | Gris |
| Uncommon | 25 | Vert |
| Rare | 18 | Bleu |
| Epic | 10 | Violet |
| Legendary | 5 | Doré |
| Mythical | 2 | Iridescent (shader) |

### 7.2 Familles thématiques (lore musée)

Chaque artefact appartient à une **famille** narrative qui informe son design visuel et son écriture :

- **Ancient Texts** : copypastas, lorem ipsum, phrases déroutantes (souvent Galaxy Brain).
- **Cursed Media** : GIFs maudits, images glitchées, screamers (souvent Cursed/Void).
- **Living Memes** : doge, cat, frog, autres animaux internet (souvent Chaos/Sigma).
- **Forbidden Knowledge** : equations bidons, mèmes mathématiques (Galaxy Brain).
- **Internet Apocrypha** : creepypastas, ARG mèmes (Cursed).

(La famille n'a pas de mécanique en V1, c'est purement narratif/cosmétique. V2 pourra ajouter des set bonuses par famille.)

### 7.3 Rareté → puissance (en run)

| Rareté | Stats relatives | Apparition draft |
|---|---|---|
| Common | 1.0× | Très fréquente |
| Uncommon | 1.4× | Fréquente |
| Rare | 2.0× | Boss/Élite/Shop principalement |
| Epic | 3.0× | Élite/Boss + occasionnel shop |
| Legendary | 4.5× | Boss zone 2-3 + shop fin de run |
| Mythical | 6.0× | Boss final + meta-unlock-only |

### 7.4 Déblocage de cartes (méta)

Une carte **doit être débloquée en méta** avant d'apparaître dans le pool de draft d'un run. Sources de déblocage :

| Source | Détail |
|---|---|
| Run completion | 1 artefact permanent par run (cf. §5.6) |
| Reliquaire | Pack acheté en Essence au musée — 1 carte aléatoire dans le pool non-débloqué |
| Achievement reward | ~30 cartes spécifiques liées à des achievements |
| Boss-kill unique | Chaque boss V1 a 1 artefact unique débloqué à sa première défaite |

### 7.5 Reliquaires (méta-pack)

| Reliquaire | Coût | Contenu | Garantie |
|---|---:|---|---|
| Common | 100 Essence | 1 carte non-débloquée | — |
| Uncommon | 500 Essence | 1 carte non-débloquée Uncommon+ | Uncommon+ garanti |
| Rare | 2 500 Essence | 1 carte non-débloquée Rare+ | Rare+ garanti |
| Epic | 12 500 Essence | 1 carte non-débloquée Epic+ | Epic+ garanti, garantie Legendary tous les 10 |
| Mythical | 5 Fame + 50 000 Essence | 1 carte non-débloquée Mythical | Mythical garanti |

**Pas de RNG agressif** : si le joueur a débloqué toutes les cartes Common, le Reliquaire Common ne s'affiche plus. Pas de doublons inutiles.

### 7.6 Doublons et fusion

Les cartes obtenues en run **ne sont pas conservées comme doublons** (run = perte). Mais en méta :

- Reliquaire qui drop une carte déjà débloquée → conversion automatique en Essence (valeur du tier).
- **Pas de fusion v1** : la fusion mobile (§7.5 v2) est retirée. La progression de niveau d'une carte se fait par **upgrades en run** uniquement (Repos node, certains events). À la fin du run, toutes les upgrades sont perdues.

### 7.7 Décision : niveau de carte ?

V1 : **niveau de carte = niveau au sein d'un run uniquement** (1 à 5, +20% stats par niveau). En méta, toutes les cartes sont niveau 1 par défaut.

Cela simplifie radicalement la méta vs v2 et empêche le grind idle de trivialiser les runs.

---

## 8. Musée Tycoon-Incrémental (Méta)

### 8.1 Rôle

Le musée est la **couche idle** entre les runs. Il :

1. **Affiche** les artefacts collectés (satisfaction visuelle, achievement de complétion).
2. **Génère** Essence + Fame en idle (idle income).
3. **Multiplie** les bonus méta selon adjacence/rooms (réflexion stratégique entre runs).
4. **Finance** les Reliquaires, déblocages de zones, prestige.

### 8.2 Tiers du musée

| Tier | Nom | Slots | Coût débloquage | Niveau requis |
|---:|---|---:|---|---:|
| 1 | Starter Hall | 4 | Gratuit (post-tutoriel) | 1 |
| 2 | Curator's Office | 8 | 1 500 Essence | 3 |
| 3 | Gallery | 16 | 15 000 Essence | 10 |
| 4 | Forbidden Wing | 32 | 150 000 Essence + 10 Fame | 20 |
| 5 | Cursed Vault | 64 | 1 500 000 Essence + 50 Fame | 35 |
| 6 | Eternal Archive | 128 | 15 000 000 Essence + 200 Fame + Prestige 1 | 50 |

### 8.3 Formule de revenu par stand

```
income_per_minute(slot) =
    base_rarity_value(card.rarity)
  × aspect_set_bonus(museum)
  × adjacency_multiplier(slot)
  × room_theme_bonus(slot.room, card.aspect)
  × prestige_global_multiplier
```

Détails :

- `base_rarity_value` : Common 1, Uncommon 3, Rare 9, Epic 27, Legendary 81, Mythical 243 Essence/min
- `aspect_set_bonus` : 1.0 base, +0.05 par carte unique du même aspect exposée (max +0.5)
- `adjacency_multiplier` : 1.0 base, +0.10 par voisin (H/V uniquement) du **même aspect**, max ×1.4
- `room_theme_bonus` : 2.0 si la room est dédiée à l'aspect de la carte ET set complet, sinon 1.0
- `prestige_global_multiplier` : 1.0 base, +0.25 par prestige (max ×6 à Prestige 20)

### 8.4 Adjacence — règles

- Calcul **uniquement horizontal et vertical**, pas de diagonale (lisibilité).
- Hover sur un stand affiche les voisins comptés (highlight bleu).
- Réorganisation **gratuite et instantanée** (le musée est un puzzle de placement).

### 8.5 Rooms thématiques

À partir du Tier 3, les slots sont groupés en "rooms" de 4-8 slots. Chaque room peut être assignée à un aspect :

- Set d'un aspect complet placé dans une room dédiée à cet aspect → **room "synchronisée"** = ×2 revenu local.
- Une room peut héberger plusieurs aspects mais ne synchronise jamais.
- Changement de thème de room : 1 000 Essence.

### 8.6 Idle income — règles non négociables

- **Cap offline** : 8h (480 min). Au-delà, plateau dur.
- **Pause complète pendant un run** : `MuseumIdleClock.pause()` au start, `resume()` au retour hub.
- **Pas de FOMO** : aucun event, aucun bonus, aucune ressource ne se perd si tu ne te connectes pas.
- **Pas de skip-timer payant** : il n'y a pas de timer dans le musée à skip de toute façon (pas de fusion, pas de craft long).
- **L'idle ne trivialise pas les runs** : le revenu idle finance les Reliquaires (variété) et le prestige (déblocages). Il **ne donne pas de buff direct en run**. Aucune stat de run n'est augmentée par le temps réel offline.

### 8.7 Burst de retour

À l'entrée du hub après absence :

- Animation cinématique courte (2-3s) : pluie d'Essence, son satisfaisant, modal "+X Essence (8h offline cap)".
- Skippable au tap.

---

## 9. Économie & Progression

### 9.1 Devises

| Devise | Source | Usage |
|---|---|---|
| **Essence** | Idle musée, run drops, vente doublons | Achat reliquaires, déblocage rooms, achats run shop |
| **Fame** | Boss runs, achievements, Mythical drops | Déblocage Tier 4+, Reliquaire Mythical, prestige threshold |
| **XP joueur** | Combat, achievements | Niveau profil → débloque tiers, slots actifs, curateurs |

**Suppression v2** : Gems, Display Crystals (renommé Fame).

**Règle absolue** : **aucune devise n'est achetable en argent réel.** Cursed Museum est paid game one-shot Steam.

### 9.2 Progression de niveau joueur

- Niveau 1 → 50 V1, courbe XP exponentielle douce (1.15× par niveau)
- Récompenses par level : Essence, Fame, Reliquaires gratuits, slots de deck
- Niveau 1 : 1 deck de 4 cartes (loadout)
- Niveau 5 : 2 decks (sauvegardes équipe)
- Niveau 15 : 3 decks
- Niveau 30 : 4 decks
- Déblocage Curateurs : Curateur 2 lvl 8, Curateur 3 lvl 20, Curateur 4 lvl 35

### 9.3 Prestige

- **Conditions V1** : niveau 50 + Tier 5 musée complet + 1 victoire en Ascension 5+.
- **Reset** : Essence à 0, niveau à 1, slots musée vidés (cartes retournent à l'inventaire), tiers musée verrouillés sauf Tier 1.
- **Conservé** : collection complète (cartes débloquées), Fame, achievements, Curateurs débloqués, Reliques Méta débloquées, Ascension max atteinte.
- **Gain par prestige** :
  - +1 Prestige Star → +0.25× sur revenu musée global (jusqu'à ×6 max à Prestige 20).
  - Débloque +1 slot dans le pool de reliques de départ.
  - Tier 6 (Eternal Archive) débloqué à Prestige 1.

### 9.4 Économie soft cap

- Tous les contenus V1 atteignables en ~30-50h de jeu actif (à valider en simulation).
- Prestige 1 cible ~15-25h.
- Ascension max (20) cible 50-80h.
- Pas de soft cap artificiel, pas de "wait timer" pour avancer.

### 9.5 Pas de monétisation V1

- **Prix Steam target** : 14.99 € EA, 19.99 € 1.0.
- **Pas d'IAP, pas de DLC à la sortie.**
- DLC potentiels V2+ : nouvelles familles d'artefacts (ex: "Y2K Pack", "Vine Era Pack"), nouveaux Curateurs, nouvelles zones. Toujours additif, jamais bloquant pour le contenu de base.

---

## 10. Architecture technique Godot

### 10.1 Stack technique

| Élément | Choix | Justification |
|---|---|---|
| Engine | **Godot 4.6 stable** | PC mature en 2026, Steam Deck supporté natif |
| Language | **GDScript** | Vélocité, hot reload, scope V1 ne justifie pas C# |
| Rendu | **Forward+ (PC haut)** + **Forward Mobile (Steam Deck)** | Toggle automatique selon perf |
| Save | **Custom encrypted JSON** + binaire pour cartes | Anti-tamper léger, taille raisonnable |
| Cloud save | **Steam Cloud** via Steamworks GDExtension | Standard Steam |
| Steam SDK | **GodotSteam (GDExtension)** | Achievements, Cloud, Workshop V2 |
| Analytics | **Sentry** (crash) + **PostHog** (funnel) | RGPD-compatible, opt-in côté joueur |
| Audio | Godot natif + bus dynamique | Bus Music/SFX/UI séparés pour ducking |
| Localisation | Godot CSV + `tr()` | FR + EN V1 |

### 10.2 Architecture de code

#### Autoloads (singletons globaux)

```
res://autoload/
├── EventBus.gd          # Signal hub global, découplage modules
├── GameState.gd         # État du joueur (niveau, currencies, prestige, ascension)
├── Inventory.gd         # Cartes débloquées (méta), reliques méta débloquées
├── MuseumState.gd       # État du musée (slots, rooms, tiers)
├── MuseumIdleClock.gd   # Tick idle, pause/resume, offline calc
├── RunState.gd          # État RUN ACTIF (deck, reliques run, map, position) — null si pas en run
├── Economy.gd           # Calculs économiques (income tick, reliquaire costs, prestige)
├── BattleEngine.gd      # Moteur déterministe de bataille
├── RunEngine.gd         # Orchestrateur de run (map gen, node resolve, draft)
├── SaveSystem.gd        # Persistance encrypted local + Steam Cloud
├── SteamBridge.gd       # Wrapper GodotSteam (achievements, cloud, presence)
├── AudioManager.gd      # Bus, ducking, pool de players
├── Localization.gd      # Wrapper tr() avec fallback
└── Analytics.gd         # Sentry + PostHog gateway
```

#### Resources (data-driven)

```
res://data/
├── cards/               # Une .tres par artefact (100 fichiers V1)
├── relics/              # Une .tres par relique (80 fichiers V1)
├── curators/            # 4 curateurs V1
├── enemies/             # EnemyData.tres pour PvE
├── zones/               # ZoneData.tres × 3 (3 zones par run V1) + boss
├── rooms/               # RoomTemplate.tres pour layout musée
├── reliquaires/         # ReliquaireDefinition.tres × 5
├── events/              # EventData.tres × 30+
└── localization/        # *.csv
```

#### Scènes principales

```
res://scenes/
├── main/
│   ├── Main.tscn              # Boot scene, charge save, route vers Hub
│   └── Boot.gd
├── hub/
│   ├── MuseumHub.tscn         # Scène hub méta principale (paysage 16:9)
│   ├── Stand.tscn             # Slot d'exposition
│   ├── Room.tscn              # Groupe de slots
│   └── HubButtons.tscn        # Curator select / Reliquaire / Run portal / Prestige
├── run/
│   ├── PreRunSetup.tscn       # Curateur, deck starter, reliques départ, difficulté
│   ├── RunMap.tscn            # Map StS-like
│   ├── NodeView.tscn          # Vue d'un nœud (combat/event/shop/repos/élite/trésor/boss)
│   ├── DraftScreen.tscn       # Choix carte/relique post-combat
│   ├── ShopScreen.tscn        # Shop in-run
│   ├── EventScreen.tscn       # Event narratif
│   └── RunResult.tscn         # Écran fin de run
├── battle/
│   ├── BattleScreen.tscn      # Vue combat
│   ├── CardActor.tscn         # Une carte en combat (sprite + stats)
│   ├── DamagePopup.tscn
│   ├── HealthBar.tscn
│   └── ResultScreen.tscn      # Inter-combat (post-combat avant draft)
├── collection/
│   ├── CollectionView.tscn    # Grille des cartes débloquées
│   ├── CardDetail.tscn
│   └── DeckBuilder.tscn       # Compose équipe de 4 (méta loadout)
├── shop_meta/
│   ├── ReliquaireShop.tscn    # Achat reliquaires (méta)
│   └── ReliquaireOpening.tscn # Animation reveal
├── prestige/
│   └── PrestigeAltar.tscn
└── ui_common/
    ├── TopBar.tscn            # Currencies + level + retour hub
    ├── PauseMenu.tscn
    └── Toast.tscn
```

### 10.3 Pattern Effect/Passive composable

Inspiré des frameworks Godot card game (db0/godot-card-game-framework, chun92/card-framework) :

```gdscript
class_name CardEffect extends Resource

enum Trigger { ON_BATTLE_START, ON_HIT, ON_KILL, ON_TURN_END, ON_STAGGER }
@export var trigger: Trigger
@export var target: TargetSelector  # Resource: SELF, ENEMY_RANDOM, ALL_ALLIES, ...
@export var actions: Array[EffectAction]  # Resource: damage, heal, buff, summon, ...

func resolve(context: BattleContext) -> void:
    var targets = target.resolve(context)
    for action in actions:
        action.execute(targets, context)
```

Chaque carte a un `Array[CardEffect]` → on compose des cartes complexes sans code spécifique.

**Reliques** réutilisent le même système avec un `RelicTrigger` étendu (ON_RUN_START, ON_NODE_ENTER, ON_DRAFT, ON_SHOP_ENTER, etc.) en plus des combat triggers.

### 10.4 Save format

Save chiffré avec clé dérivée du Steam ID (fallback machine GUID en mode offline) :

```json
{
  "version": 3,
  "player": {
    "level": 12,
    "xp": 1450,
    "prestige_stars": 0,
    "ascension_max": 5,
    "currencies": { "essence": 18500, "fame": 24 }
  },
  "inventory": {
    "cards_unlocked": ["ancient_copypasta", "quantum_cat", ...],
    "meta_relics_unlocked": ["echo_chamber"],
    "curators_unlocked": ["the_archivist", "the_glitch"]
  },
  "museum": {
    "tier": 3,
    "slots": [
      { "x": 0, "y": 0, "card_id": "ancient_copypasta" },
      ...
    ],
    "rooms": [{ "id": 0, "theme": "chaos" }, ...]
  },
  "decks": [{ "name": "Main", "cards": ["ancient_copypasta", ...] }],
  "settings": { "sound": 0.8, "music": 0.6, "battle_speed": 1, "screen_shake": 1.0 },
  "active_run": null,
  "last_seen_unix": 1714670400,
  "checksum": "sha256:..."
}
```

`active_run` est non-null si l'utilisateur a un run en cours. Permet de reprendre un run interrompu (kill app, crash) en gardant l'état complet de la map et du deck run-time.

### 10.5 Performance budgets PC

| Métrique | Cible PC mid | Cible Steam Deck |
|---|---|---|
| FPS combat | 60 stable | 30 stable, 60 idéal |
| RAM peak | < 1.5 GB | < 1 GB |
| Build size | < 1 GB total | identique |
| Cold start | < 5s | < 8s |
| Texture atlas | 4096×4096 max PC, 2048×2048 Deck | mipmaps activés |

**Steam Deck Verified target** : navigation full-pad, lisibilité 1280×800, pas de UI mouse-only, indication des contrôles dynamique selon input.

### 10.6 Asset pipeline IA

> Identique au v2 §9.7. Voir détails ci-dessous.

**Décision V1** : 100% des visuels (artefacts, environnements musée, ennemis, FX statiques, icônes, reliques) sont produits via IA générative pour atteindre une qualité élevée à coût réduit.

#### Stack de génération recommandée

| Usage | Outil principal | Alternative | Notes |
|---|---|---|---|
| Portraits artefacts (100 cartes V1) | **Flux 1.1 Pro** ou **Imagen 4** via API | Midjourney v7 | Style consistant via embedding/LoRA |
| Icônes reliques (80 V1) | **Flux 1.1 Pro** style flat | Génération + vectorisation Vector Magic | SVG > PNG si possible |
| Environnements musée (rooms, props) | **Flux 1.1 Pro** + ControlNet | Stable Diffusion XL fine-tuned | Génération en tiles 256/512 |
| Animations 2D (idle, attack, hurt) | **Animate Anyone** / **Pika 2.0** + cleanup | Frame-par-frame + interpolation | 4-8 frames par anim suffit |
| FX particles | **Génération texture** seule, particles en code | - | Atlas de fumée/étincelles |
| Icônes UI | **Flux 1.1 Pro** style flat | - | Atlas global |

#### Cohérence stylistique — non négociable

Mêmes règles que v2 (style guide, LoRA entraîné, prompts versionnés, review humaine ≥60% rejet).

#### Coût estimé

- Flux 1.1 Pro : ~0.04 € par image, 6 000 générations × 0.04 = **240 €**
- API IA video pour animations : ~500-1 000 €
- LoRA training (RunPod 8h A100) : ~50 €
- **Total assets V1 ≈ 1 000-1 500 €** vs 15 000-30 000 € pour artiste freelance

#### Considérations légales

- **Vérifier les CGU du modèle** utilisé pour usage commercial.
- **Pas de référence directe à des mèmes copyrightés** (Doge OK car libre, Skibidi Toilet ambigu, Pokémon NON). Curation manuelle stricte.
- **Mention "art assistance IA" dans crédits Steam page** par transparence.
- **Architecture découplée** : toutes les textures référencées par ID via Resource, prêt à refaire si évolution réglementaire.

### 10.7 Tests

- **Unit tests** sur Economy, BattleEngine (déterminisme), RunEngine (gen map seedée), SaveSystem → framework `gdUnit4`.
- **Integration tests** sur boucles : run start → combat → draft → shop → boss → run end → museum update.
- **Snapshot tests** sur résultats de bataille (seed → JSON trace stable). 1000 simulations CI.
- **Snapshot tests run** : seed → graphe map identique, drops identiques, résultat boss identique.
- **PC test pipeline** : build Linux headless → exécution tests, build Windows + macOS smoke test sur CI.

---

## 11. Variété et rejouabilité

### 11.1 Variété de builds (ce qui rend le roguelite addictif)

- **5 aspects × 100 cartes × 80 reliques × 4 curateurs** → espace combinatoire largement >10⁵ builds testables.
- **Synergies cartes/cartes** : ex. cartes Cursed buffant cartes Cursed adjacentes en formation.
- **Synergies cartes/reliques** : ex. relique "Echo Chamber" double les passifs Cursed.
- **Synergies reliques/reliques** : ex. "Critical Mass" + "Mind Spike" → chains de crit.
- **Pickup risk/reward** : reliques "Cursed" donnent un gros buff mais avec un malus permanent run.

### 11.2 Mode Ascension

À partir de la première victoire, débloque **Ascension 1**. Chaque niveau ajoute un modifier :

| Niveau | Modifier ajouté |
|---|---|
| 1 | Ennemis +10% HP |
| 2 | -1 carte starter |
| 3 | Boss zone 1 a +1 phase Surge |
| ... | ... |
| 20 | Final Ascension : tous les modifiers cumulés |

Ascensions cumulent. Ascension 20 = challenge "1cc" pour les hardcore players.

### 11.3 Daily / Weekly Expeditions

- **Daily** : seed publique fixe pour 24h. Tout le monde joue le même run. Leaderboard local + Steam (V2).
- **Weekly** : seed avec modifiers spéciaux ("Mono-Cursed", "No Reliques", "Double Boss"). Récompense Fame fixe une fois par semaine.
- Pas de FOMO : si tu rates une daily, tu ne perds rien. Le leaderboard avance, c'est tout.

### 11.4 Achievements Steam

- **100+ achievements V1.**
- Catégories : Collection (X cartes débloquées par rareté), Build (gagner avec mono-aspect), Domination (boss vaincu en X tours), Méta (atteindre prestige 1, Ascension 20), Découverte (déclencher 50% des events au moins une fois).

---

## 12. Roadmap modulaire (V1 → V3)

### V1 — Steam Early Access (4-5 mois équipe de 2-3)

Cible : 100 cartes, 80 reliques, 4 curateurs, 3 zones × boss, autobattle déterministe complet, musée 6 tiers + prestige, daily + weekly, FR + EN.

**Contenu**
- 100 artefacts (40 Common, 25 Uncommon, 18 Rare, 10 Epic, 5 Legendary, 2 Mythical)
- 80 reliques (40 Common, 25 Uncommon, 10 Rare, 5 Boss)
- 4 Curateurs (héros) avec deck starter unique
- 3 zones avec 12-16 nœuds chacune
- 3 boss (1 par zone, 1 par aspect dominant)
- 30+ events narratifs

**Features**
- Hub musée 16:9 PC paysage
- Roguelite run avec map StS-like, draft, shop, repos, événements
- Autobattle déterministe avec juice complet
- Collection + deck builder (4 cartes loadout)
- Musée 6 tiers, adjacence, rooms thématiques, idle income capé 8h
- Reliquaires (5 tiers)
- Prestige
- Mode Ascension 0-20
- Daily + Weekly seed
- Steam Cloud + Achievements
- FR + EN

### V2 — Steam 1.0 (3-4 mois post-EA)

- 50 nouvelles cartes (ex: pack thématique "Y2K Era")
- 30 nouvelles reliques
- 2 nouveaux Curateurs
- 1 nouvelle zone (zone 4 optionnelle pour Ascension 10+)
- Steam Workshop pour custom seeds / défis
- Leaderboards Steam Daily/Weekly
- Custom Run mode

### V3 — Endgame & DLC (6-12 mois post-1.0)

- DLC payants thématiques (~5-10 € chacun, additif uniquement).
- Endless Mode (zone qui scale infinie).
- Twitch integration (chat vote pour drafts, V3 stretch).
- Mod tools (V3 stretch).

---

## 13. Backlog Symphony — Modules & tickets

> **Cette section est conçue pour être consommée par Symphony.**
> Chaque module est un epic Linear. Chaque ticket est une unité atomique de travail pour un agent Codex.
> Les tickets sont ordonnés par dépendance topologique : un agent peut prendre n'importe quel ticket dont les dépendances `[deps: ...]` sont closes.
> **Préfixe :** `CRSD-` (à remplacer par le team key Linear réel si différent).

### EPIC 1 — Bootstrap Godot project

- **CRSD-001** [no deps] Initialiser projet Godot 4.6, structure de dossiers (`autoload/`, `data/`, `scenes/`, `assets/`), `.gitignore`, README.
- **CRSD-002** [deps: 001] Configurer export presets Windows + Linux + macOS pour Steam (sans signing pour V1 dev).
- **CRSD-003** [deps: 001] Mise en place CI GitHub Actions : lint GDScript, tests `gdUnit4`, export debug Linux headless.
- **CRSD-004** [deps: 001] Définir thème UI global Godot 16:9 paysage (typographie, palette, sizes Steam Deck-readable). Charger en autoload.
- **CRSD-005** [deps: 001] Intégrer GodotSteam (GDExtension), stub `SteamBridge.gd` autoload avec init/shutdown.

### EPIC 2 — Data layer (Resources)

- **CRSD-010** [deps: 001] Créer classe `CardData` Resource avec tous les champs §6.6 (incluant `aspect: Aspect` enum à 5 valeurs).
- **CRSD-011** [deps: 010] Créer classes `PassiveEffect`, `UltimateAbility`, `CardEffect`, `EffectAction`, `TargetSelector` (composables).
- **CRSD-012** [deps: 010] Créer classe `RelicData` Resource (§6.7).
- **CRSD-013** [deps: 010] Créer classe `CuratorData` Resource (loadout starter, passif global de run).
- **CRSD-014** [deps: 010] Créer `EnemyData`, `ZoneData`, `RoomTemplate`, `EventData` Resources.
- **CRSD-015** [deps: 014] Créer `ReliquaireDefinition` Resource avec coût, garanties, pool filter.
- **CRSD-016** [deps: 010, 012] Générer 10 cartes test + 8 reliques test (.tres) pour dev.

### EPIC 3 — Save & state

- **CRSD-020** [deps: 001] Implémenter `SaveSystem` autoload : sauvegarde JSON encrypted local, charge à boot.
- **CRSD-021** [deps: 020] Implémenter `GameState` autoload : currencies (Essence, Fame), level, XP, prestige, ascension max.
- **CRSD-022** [deps: 020] Implémenter `Inventory` autoload : cartes débloquées (méta), reliques méta, curateurs.
- **CRSD-023** [deps: 020] Implémenter `MuseumState` autoload : slots, rooms, tiers.
- **CRSD-024** [deps: 020] Implémenter `RunState` autoload : null si pas en run, sinon état complet du run actif (map, deck, reliques, position).
- **CRSD-025** [deps: 020] Migration de save format v2 → v3 (champ `version` + handler) — note : v2 mobile mort, mais format reste prêt à evoluer.
- **CRSD-026** [deps: 020-024] Tests unitaires : save → quit → load → state intact, y compris run en cours.
- **CRSD-027** [deps: 020, 005] Steam Cloud sync : pull à boot, push après chaque save.

### EPIC 4 — Museum (méta-hub)

- **CRSD-030** [deps: 010, 021, 023] Scène `MuseumHub.tscn` 16:9 paysage, layout statique avec zones interactives (Run portal, Reliquaire shop, Curator select, Prestige altar, Settings).
- **CRSD-031** [deps: 030] Scène `Stand.tscn` cliquable, affiche carte exposée, hover affiche income preview.
- **CRSD-032** [deps: 031] Drag-and-drop card depuis Inventory vers Stand.
- **CRSD-033** [deps: 031] Calcul `Economy.compute_slot_income()` selon formule §8.3.
- **CRSD-034** [deps: 033] Tick d'income en temps réel (1Hz), affichage flottant sur stand.
- **CRSD-035** [deps: 033] Calcul adjacence H/V uniquement, highlight visuel des voisins comptés.
- **CRSD-036** [deps: 030] Tier locking : seuls les slots du tier courant + précédents sont affichés.
- **CRSD-037** [deps: 030, 036] Achat tier supérieur : UI confirmation, déduction Essence, animation déblocage.
- **CRSD-038** [deps: 030] Système de Rooms (Tier 3+), assignation thème, calcul bonus thématique.
- **CRSD-039** [deps: 020, 033] Idle income offline : calcul à login, burst visuel, cap 8h.
- **CRSD-040** [deps: 024, 033] `MuseumIdleClock.pause()` au start d'un run, `resume()` au retour. Test : aucune Essence générée pendant un run.

### EPIC 5 — Collection & Reliquaire shop

- **CRSD-050** [deps: 022] Scène `CollectionView.tscn` : grille filtrable par rareté/aspect/famille.
- **CRSD-051** [deps: 050] Scène `CardDetail.tscn` : stats, lore, button "exposer", "ajouter au deck".
- **CRSD-052** [deps: 022] Scène `DeckBuilder.tscn` : sélection 4 cartes, validation type diversity warning.
- **CRSD-053** [deps: 015, 022] Scène `ReliquaireShop.tscn` : 5 tiers de reliquaires visibles, drop rates affichés.
- **CRSD-054** [deps: 053] `Inventory.open_reliquaire(reliquaire_id)` : RNG seedé, applique garanties, return carte.
- **CRSD-055** [deps: 054] Scène `ReliquaireOpening.tscn` : animation reveal carte, hiérarchie visuelle par rareté.

### EPIC 6 — Battle engine (réutilise v2)

- **CRSD-060** [deps: 010, 011] `BattleEngine.gd` autoload : entrée `start_battle(player_deck, enemy_team, seed)`.
- **CRSD-061** [deps: 060] `BattleRNG` : wrapper sur `RandomNumberGenerator` seedé.
- **CRSD-062** [deps: 060] State machine 7 phases (§6.2), transitions par timer + événements.
- **CRSD-063** [deps: 060] Type matchup ×1.5 / ×0.66 / ×1, application au damage calc.
- **CRSD-064** [deps: 063] Système Stagger (§6.4).
- **CRSD-065** [deps: 062] Resonance Surges (§6.5) en phase 3 et 5.
- **CRSD-066** [deps: 011, 060] Resolution des `CardEffect` selon trigger.
- **CRSD-067** [deps: 060] Output : `BattleResult` resource (winner, damage_log, mvp, drops).
- **CRSD-068** [deps: 067] Tests déterminisme : même seed → même résultat (1000 simulations).
- **CRSD-069** [deps: 060, 012] Resolution `RelicData` triggers (ON_BATTLE_START, ON_HIT, ON_KILL).

### EPIC 7 — Run engine (roguelite)

- **CRSD-070** [deps: 014, 024] `RunEngine.gd` autoload : entrée `start_run(curator, deck, starter_relics, ascension, seed)`.
- **CRSD-071** [deps: 070] `RunRNG` distinct du BattleRNG : seed du run + node index.
- **CRSD-072** [deps: 070] Génération map StS-like (graphe, types de nœuds, validation chemins, boss en fin).
- **CRSD-073** [deps: 072] `RunMap.tscn` UI : affichage graphe, nœuds, position joueur, curseur sélection.
- **CRSD-074** [deps: 070, 067] Resolution nœud Combat : start_battle → result → drops.
- **CRSD-075** [deps: 070, 067] Resolution nœud Élite : start_battle (variant) → drop garanti.
- **CRSD-076** [deps: 070] Resolution nœud Event : `EventScreen.tscn` avec choix narratifs.
- **CRSD-077** [deps: 070] Resolution nœud Shop : `ShopScreen.tscn` avec 3 cartes + 2 reliques + consommables.
- **CRSD-078** [deps: 070] Resolution nœud Repos : heal / upgrade / map-relire.
- **CRSD-079** [deps: 070] Resolution nœud Trésor : drop relique gratuite.
- **CRSD-080** [deps: 070] Resolution nœud Boss : combat boss + drops boss-only.
- **CRSD-081** [deps: 074] Draft post-combat : `DraftScreen.tscn` 1 parmi 3 cartes ou skip.
- **CRSD-082** [deps: 070] `RunResult.tscn` : écran fin de run (victoire/mort/abandon), drops méta, retour hub.
- **CRSD-083** [deps: 070] Reprise run interrompu (depuis save `active_run`).

### EPIC 8 — Battle UI & juice (réutilise v2)

- **CRSD-090** [deps: 060] Scène `BattleScreen.tscn` paysage 16:9, layout 4 cartes vs 4 cartes.
- **CRSD-091** [deps: 090] Scène `CardActor.tscn` : sprite, idle anim, attack anim, hurt anim.
- **CRSD-092** [deps: 090] Scène `HealthBar.tscn` dual : barre active + ghost retardée.
- **CRSD-093** [deps: 090] Scène `DamagePopup.tscn` : tween up+fade, color par type.
- **CRSD-094** [deps: 090] Hit-stop : `Engine.time_scale` 80-120ms, plus long sur Mythical/finishers.
- **CRSD-095** [deps: 090] Screen shake `Camera2D.offset` max 10px PC, accessibility toggle.
- **CRSD-096** [deps: 090] Audio impacts : `AudioStreamPlayer` pool + ducking musique.
- **CRSD-097** [deps: 090] Particles type halo on hit.
- **CRSD-098** [deps: 067] Scène inter-combat post-battle : MVP, drops, button "draft" / "next".
- **CRSD-099** [deps: 090] Speed toggle 1×/2×/4× persistant + auto-skip option.

### EPIC 9 — Pré-run & contenu

- **CRSD-100** [deps: 013, 022] Scène `PreRunSetup.tscn` : choix curateur, deck starter, reliques départ, ascension.
- **CRSD-101** [deps: 014, 070] 100 artefacts V1 (.tres) en data/cards/.
- **CRSD-102** [deps: 012] 80 reliques V1 (.tres) en data/relics/.
- **CRSD-103** [deps: 013] 4 curateurs V1 (.tres) en data/curators/.
- **CRSD-104** [deps: 014] 3 zones V1 (1 boss chacune) avec configurations de génération map.
- **CRSD-105** [deps: 014] 30+ events V1 (.tres) en data/events/.
- **CRSD-106** [deps: 080] 3 boss V1 avec patterns de comportement spécifiques (un boss qui punit le mono-type, un qui reflète, un qui scale avec relique count).

### EPIC 10 — Progression méta

- **CRSD-110** [deps: 021, 067] XP gain par combat, level up FX.
- **CRSD-111** [deps: 110] Level rewards (Essence, Fame, Reliquaires, slots de deck).
- **CRSD-112** [deps: 021] Conditions prestige : level 50 + Tier 5 complet + Ascension 5+.
- **CRSD-113** [deps: 112] Action prestige : reset partiel, garde collection, +1 star.
- **CRSD-114** [deps: 070] Mode Ascension 0-20 avec modifiers cumulatifs.
- **CRSD-115** [deps: 070] Daily seed généré à 00h UTC, persisté en Steam Cloud.
- **CRSD-116** [deps: 070] Weekly seed généré le lundi 00h UTC avec modifier spécial.

### EPIC 11 — Onboarding

- **CRSD-120** [deps: 030, 100, 070] Tutoriel guidé V1 : premier run guidé avec choix forcés, présentation map/draft/combat/résultat.
- **CRSD-121** [deps: 120] Skip tutoriel disponible après login 1.
- **CRSD-122** [deps: 030] Tooltip system pour mécaniques avancées (Stagger, Surge, Adjacence).

### EPIC 12 — Steam integration

- **CRSD-130** [deps: 005] Steam Achievements : intégrer 50+ achievements V1 (collection, build, domination, méta).
- **CRSD-131** [deps: 005, 027] Steam Cloud : save sync + conflict resolution (last-write-wins V1).
- **CRSD-132** [deps: 005] Steam Rich Presence : "In Run – Zone 2", "Browsing Museum", "Ascension 5".
- **CRSD-133** [deps: 005] Steam Deck input : detect controller mode, switch UI hints, navigation focus complète.

### EPIC 13 — Asset pipeline IA (parallèle au dev code)

- **CRSD-AS-001** [no deps] Style discovery : générer 30 portraits artefacts test sur 5 prompts différents, choisir style consensus équipe.
- **CRSD-AS-002** [deps: AS-001] Entraîner LoRA "Cursed Museum Style" sur 30 portraits validés (RunPod A100 ~8h).
- **CRSD-AS-003** [deps: AS-002] Définir prompt template versionné `assets/prompts/card_portrait.md` avec variables `{name}`, `{aspect}`, `{rarity}`, `{family}`.
- **CRSD-AS-004** [deps: AS-003] Pipeline batch : script Python qui lit `data/cards/*.tres`, génère portraits via API Flux, output dans `assets/cards/portraits/`.
- **CRSD-AS-005** [deps: AS-004] Review queue : web UI simple (Streamlit) pour valider/rejeter chaque sprite. Stocke le statut.
- **CRSD-AS-006** [deps: AS-005] Atlas builder : packer les portraits validés en atlas WebP par rareté avec Godot ImporterPlugin custom ou TexturePacker CLI.
- **CRSD-AS-007** [deps: AS-002] Pipeline animations : génération 4-frame idle/attack/hurt par carte via Animate Anyone, cleanup manuel, export WebP+JSON.
- **CRSD-AS-008** [deps: AS-001] Style guide environnements musée : palette/lighting/niveau de détail, validation 5 tiles musée test.
- **CRSD-AS-009** [deps: AS-008] Génération 50 props/tiles musée par room theme.
- **CRSD-AS-010** [deps: AS-001] Génération 100+ icônes UI flat style cohérent + 80 icônes reliques.
- **CRSD-AS-011** [no deps] Audit légal : vérifier CGU des modèles utilisés pour usage commercial Steam, documenter dans `LEGAL.md`.

### EPIC 14 — Polish & ship

- **CRSD-140** [deps: tous] QA : Windows 10/11, Linux Ubuntu, macOS, Steam Deck (priorité Verified).
- **CRSD-141** [deps: tous] Crash reporting Sentry intégré (opt-in à first launch).
- **CRSD-142** [deps: tous] Analytics PostHog : funnel run start, retention sessions.
- **CRSD-143** [deps: tous] Localization FR + EN complète, review native.
- **CRSD-144** [deps: tous] Steam page : screenshots, trailer, description (FR + EN).
- **CRSD-145** [deps: tous] Soft launch EA : sortie EA, monitor 2 semaines, hotfixes rapides.

---

## 14. Risques & questions ouvertes

| ID | Risque | Sévérité | Mitigation |
|---|---|---|---|
| R1 | Roguelite saturated market sur Steam | **Moyen** | Différenciation par autobattle + idle museum, pas un nième StS-clone |
| R2 | Brainrot meme cycle court → contenu obsolète | Moyen | Architecture séparée content/code, packs DLC saisonniers |
| R3 | Autobattle perçu comme "boring" sans contrôle | Moyen | Investir lourd dans le juice §6.9, MVP screen post-combat |
| R4 | Performance Steam Deck | Moyen | Forward Mobile + atlas 2048, FPS adaptatif 30/60, profiling tôt |
| R5 | Coût éditeur (Codex tokens) si Symphony tourne 24/7 | Bas | Cap concurrent agents à 3 dans WORKFLOW.md, surveillance |
| R6 | Save corruption (Steam Cloud conflict) | Haut | Save atomique (write-to-tmp + rename), checksum, last-write-wins V1 |
| R7 | Idle musée trivialise les runs | **Haut** | Règle non-nego §3.2 + §8.6 : aucun buff direct run depuis méta. Soft cap testing en sim. |
| R8 | RNG seedé déterministe casse au moindre changement de version | Moyen | Versioning explicite des seeds : invalider Daily si patch breaking |

### Questions à trancher avant V1

1. ~~Plateforme cible~~ → **DÉCIDÉ : Steam (Windows + Linux + macOS + Steam Deck Verified).**
2. ~~Audience~~ → **DÉCIDÉ : roguelite/deckbuilder Steam, 18-35.**
3. ~~Style visuel~~ → **DÉCIDÉ : 2D full, sprites générés par IA.** Voir §10.6.
4. **Curateurs starting deck** : pré-définis fixes ou semi-randomisés ?
5. **Gestion des doublons** : conversion auto Essence ou stockage pour fusion future V2 ?
6. **Voix audio** : narration tutoriel par voix ? FR + EN double cost.
7. **Workshop V2** : autoriser custom seeds ou aussi custom cartes/reliques ?

---

## 15. Glossaire

- **Artefact** : carte de combat dans le lore musée. Synonyme : "carte".
- **Aspect** : type d'artefact (Chaos/Cursed/Galaxy Brain/Sigma/Void). Synonyme : "type".
- **Essence** : devise principale, idle musée + run drops. Achat reliquaires, déblocages, run shops.
- **Fame** : devise hard, drops boss + achievements. Déblocage tiers hauts, prestige threshold, Reliquaire Mythical.
- **Stagger** : état d'étourdissement d'une carte après 3 hits super-efficaces, ×1.75 dégâts reçus.
- **Resonance Surge** : événement temporaire en phase 3 et 5 qui boost un aspect / change le terrain.
- **Run / Expédition** : partie roguelite de 30-50 min sur une map StS-like, 3 zones, 1 boss final par zone.
- **Curateur** : héros choisi en pré-run, définit le deck starter et un passif global de run.
- **Relique** : item run-time qui modifie le comportement d'un run. 80 reliques V1.
- **Meta Relic** : relique débloquée en méta qui peut apparaître dans le pool de départ pré-run.
- **Reliquaire** : pack acheté en Essence au musée pour débloquer des artefacts dans le pool méta.
- **Tier (musée)** : niveau du musée 1→6, débloque des slots.
- **Room** : groupe de slots dans le musée, peut être thématisée à un aspect.
- **Adjacence** : voisin H/V (pas diagonale) d'un slot, source de bonus si même aspect.
- **Prestige** : reset partiel volontaire, conserve collection, donne +0.25× revenu et débloque pool.
- **Ascension** : difficulté progressive 0-20 unlock après première victoire.
- **Daily Expedition** : run avec seed publique fixe pour 24h.
- **Weekly Expedition** : run avec seed + modifier spécial chaque lundi.

---

## 16. Sources & références

### Recherche Godot
- [Godot 4 Autobattler Course (guladam)](https://github.com/guladam/godot_autobattler_course)
- [Godot Card Game Framework (db0)](https://github.com/db0/godot-card-game-framework)
- [Card Framework (chun92)](https://github.com/chun92/card-framework)
- [Godot Architecture Advice (abmarnie)](https://github.com/abmarnie/godot-architecture-organization-advice)
- [Godot Steam Deck export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_pc.html)
- [GodotSteam GDExtension](https://godotsteam.com/)

### Inspirations gameplay
- Slay the Spire (map graph, draft, transparence)
- Balatro (idle + run synergies)
- The Last Flame, He Is Coming (autobattler + reliques + builds)
- Vault of the Void (deck management, prestige roguelite)
- Tiny Rogues (méta-progression Steam)

### GDD historiques
- `DESIGN.md v2` (mobile gacha, archivé git history)

---

**Fin du document.**
**Maintenu par** : équipe Symphony + dev superviseur.
**Toute modification** : créer un ticket Linear `CRSD-DOC-*` avec changelog.
