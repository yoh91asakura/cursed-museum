# Cursed Museum Legal Audit

> Legal review aid, not legal advice. Re-check every linked term before paid
> asset production, Steam page submission, or release.

Last reviewed: 2026-05-03
Scope: `DESIGN.md` section 10.6 and ticket `CRSD-AS-011`.

## Design Requirement

`DESIGN.md` section 10.6 requires a generative-AI asset pipeline for V1
visuals: card portraits, relic icons, museum environments, static FX, UI icons,
and short 2D animation source frames. It also requires:

- checking the terms of the model used for commercial use;
- avoiding direct references to copyrighted memes or protected franchises;
- disclosing "art assistance IA" on the Steam page credits;
- keeping assets decoupled by stable IDs so they can be regenerated.

Steam distribution is commercial, paid, and player-facing. Generated visuals
that ship in the game, store page, community assets, or marketing materials
must be disclosed in Steamworks' content questionnaire.

## Executive Decision

Approved default for V1 asset generation:

1. Use **FLUX1.1 [pro] through the paid Black Forest Labs API** as the primary
   still-image source.
2. Use **Imagen 4 on Vertex AI** as a secondary still-image source only through
   a paid Google Cloud account with safety filters enabled.
3. Use **Pika** for video/animation only on a subscription tier whose current
   terms expressly permit commercial use.
4. Do not use public/free/community generations, other users' outputs, or
   non-commercial model weights for shipped assets.
5. Keep a provenance row for every generated asset before it can enter an
   approved atlas.

## Steam AI Disclosure

Primary source: Steamworks Content Survey, "Contenu genere par l'intelligence
artificielle":
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey>

Steam requires a description of generative AI use when AI is used during
development or when the product includes AI services. Steam separates:

- pre-generated content: art, code, sound, or other content created with AI
  during development;
- live-generated content: content created with AI while the game runs.

Cursed Museum V1 should disclose pre-generated AI for player-facing art and
marketing assets. V1 should not include live-generated AI unless a later ticket
adds runtime guardrails and monetization review. `DESIGN.md` currently describes
asset generation as offline production, not runtime generation.

Suggested Steam disclosure draft:

> Cursed Museum uses generative AI tools during development to assist creation
> of 2D card art, relic icons, environment props, static FX textures, and some
> animation source frames. All generated assets are manually reviewed, edited,
> and curated by the development team before inclusion. The game does not use
> live generative AI during play.

## Provider Audit

| Tool / model | Planned use in `DESIGN.md` | Commercial Steam status | Required controls |
|---|---|---|---|
| FLUX1.1 [pro] / FLUX.1 [pro] via Black Forest Labs API | Primary card portraits, relic icons, environments, UI icons | Approved with paid API/commercial terms. BFL says outputs may be used for personal or commercial purposes subject to its restrictions, while FLUX.1 `[dev]` is non-commercial unless separately licensed. | Use paid API account. Do not use FLUX.1 `[dev]` weights without a commercial license. Do not train competing models from outputs. Human-review all outputs. |
| Imagen 4 on Google Vertex AI | Alternative still-image generation | Conditional approved. Google Cloud service terms state generated output is customer data and Google does not assert ownership over new IP in generated output; usage remains subject to AUP/prohibited-use rules and safety filters. | Use paid Google Cloud/Vertex AI account. Keep safety filters enabled unless counsel approves a change. Do not use generated output to train competing models. Preserve SynthID/watermark metadata where technically practical. |
| Midjourney v7 | Alternative still images | Conditional but not preferred. Midjourney grants ownership of created assets to the extent possible, but commercial ownership has plan and revenue caveats; assets made in shared/open spaces can be visible to others, and upscaled assets from other users remain theirs. | Use only the project account's own generations. If company revenue exceeds USD 1,000,000, use Pro or Mega plan. Enable Stealth for unreleased assets where available. Never use other users' images or remixes as shipped assets without written permission. |
| Stable Diffusion XL fine-tuned | Alternative environment tiles / local generation | Conditional. The official SDXL base model card lists CreativeML Open RAIL++-M. However, every checkpoint, LoRA, embedding, ControlNet, dataset, and host may add separate terms. | Approve only exact model files with recorded licenses. No CivitAI/community checkpoint unless the asset log records commercial permission. Training data must be owned, licensed, or generated from approved sources. |
| Animate Anyone | Animation pipeline candidate | Conditional for code only. The public GitHub repository is marked Apache-2.0, but shipped animation rights also depend on input image rights, model weights, checkpoints, and any hosted service used. | Do not approve as a shipped asset source until the exact implementation path is documented. If used, record source image rights, model/checkpoint license, and generated animation review. |
| Pika 2.0 | Animation/video source frames | Conditional. Pika terms allow only personal, non-commercial use except where a subscription plan permits commercial use. | Use only a plan that expressly includes commercial use at generation time. Archive plan/terms evidence for generated clips. Do not upload third-party characters, celebrity likenesses, or copyrighted clips. |
| Vector Magic | Vectorization of generated icons | Approved as a processing tool, not a source of rights. Terms disclaim warranties and require the user to have rights in uploaded content. | Upload only project-owned/generated/licensed raster inputs. Keep generated SVGs tied to the source asset provenance row. |
| RunPod / GPU rental | LoRA training compute | Approved as infrastructure only. It does not solve dataset/model licensing. | Store no secrets in images/notebooks. Record dataset and base-model license separately. |

## Asset Provenance Requirements

Every generated asset committed under `assets/` should have a matching
provenance row before approval:

| Field | Required value |
|---|---|
| asset_id | Stable resource ID used by game data, not a file path |
| output_path | `res://assets/...` path |
| usage | Card portrait, icon, environment prop, FX texture, animation frame, marketing, etc. |
| provider | BFL, Google Vertex AI, Pika, Midjourney, local SDXL, etc. |
| model | Exact model/version/endpoint/checkpoint and commercial plan if applicable |
| generation_date | ISO date |
| prompt_template | Versioned prompt file or commit SHA |
| inputs | Uploaded images, sketches, seeds, ControlNet maps, references |
| input_rights | Own work, licensed stock with license URL, approved generated asset ID, etc. |
| reviewer | Human reviewer who accepted the asset |
| rejection_flags | IP likeness, protected meme/franchise, celebrity, logo, unsafe content, style mismatch |
| steam_disclosure_scope | In-game, store page, community asset, marketing, or internal-only |

No generated asset is release-ready without this row.

## Content Restrictions

The following are blocked for shipped assets unless a separate written license
exists:

- protected franchises, characters, logos, trade dress, or celebrity likenesses;
- direct prompt references to copyrighted memes or current internet characters
  with unclear ownership;
- other users' Midjourney/Pika/gallery outputs;
- assets generated from uploaded images that the project does not own or
  license;
- model outputs that visibly imitate a living artist's signature style when the
  prompt asked for that artist or the result is too close after review;
- live generative AI output during gameplay.

`DESIGN.md` explicitly calls out Pokemon as forbidden and Skibidi Toilet as
ambiguous. Treat any similarly protected meme/franchise as rejected by default.

## Credits And Store Page

Add this to credits and adapt it for Steam:

> Visual art production used generative AI assistance for concept exploration
> and source image generation. Final assets were manually selected, edited, and
> integrated by the development team.

This disclosure does not replace the Steamworks content questionnaire.

## Sources Reviewed

- Black Forest Labs Developer Terms of Service:
  <https://bfl.ai/legal/developer-terms-of-service>
- Black Forest Labs FLUX API Service Terms:
  <https://bfl.ai/legal/flux-api-service-terms>
- Black Forest Labs FLUX Pro model page:
  <https://bfl.ai/models/flux-pro>
- Google Cloud Service Specific Terms:
  <https://cloud.google.com/terms/service-terms>
- Google Vertex AI Imagen generation docs:
  <https://cloud.google.com/vertex-ai/generative-ai/docs/image/generate-images>
- Google Vertex AI Imagen responsible AI guidelines:
  <https://cloud.google.com/vertex-ai/generative-ai/docs/image/responsible-ai-imagen>
- Midjourney Terms of Service:
  <https://docs.midjourney.com/hc/en-us/articles/32083055291277-Terms-of-Service>
- Midjourney commercial-use help:
  <https://docs.midjourney.com/hc/en-us/articles/27870375276557-Using-Images-Videos-Commercially>
- Stability AI SDXL base model card:
  <https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0>
- HumanAIGC AnimateAnyone repository:
  <https://github.com/HumanAIGC/AnimateAnyone>
- Pika Terms of Service:
  <https://launch.pika.art/terms-of-service>
- Vector Magic Terms of Use:
  <https://vectormagic.com/policies/terms>
- Steamworks Content Survey:
  <https://partner.steamgames.com/doc/gettingstarted/contentsurvey>
