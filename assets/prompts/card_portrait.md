---
template_id: card_portrait
version: 1
variables:
  - name
  - aspect
  - rarity
  - family
---

# Card Portrait Prompt

Use this template for V1 artifact card portraits generated through the Cursed
Museum asset pipeline. Replace the variables before sending the prompt to the
image generation API.

## Variables

- `{name}`: artifact display name.
- `{aspect}`: one of Chaos, Cursed, Galaxy Brain, Sigma, or Void.
- `{rarity}`: card rarity.
- `{family}`: artifact family or collection theme.

## Positive Prompt

Cursed Museum Style LoRA, high quality 2D artifact card portrait, centered
single object composition, {name}, {rarity} rarity artifact, {aspect} aspect,
{family} family, uncanny museum exhibit, occult glass display lighting,
hand-painted stylized texture, strong silhouette, readable at small card size,
rich material detail, subtle magical aura, dark whimsical atmosphere, premium
Steam game card art, no typography.

## Negative Prompt

copyrighted character, celebrity likeness, direct meme reference, logo, text,
caption, watermark, UI frame, border, multiple objects, cluttered background,
photorealistic render, low resolution, blurry, noisy, deformed geometry, extra
limbs, gore, explicit content.

## Output Requirements

- Square portrait source image.
- Artifact must remain centered with enough margin for later card framing.
- Background should be simple museum ambience, not a detailed scene.
- Do not include names, rarity labels, aspect icons, or any other text in the
  generated image.
