# Fonts — source and licence

The app bundles four font families for the Horizon redesign (spec §2.1). All four
are under the **SIL Open Font License 1.1**; none declares a Reserved Font Name.
The licence texts are in `assets/fonts/licences/`.

| Family | Role | Weights bundled | Source (github.com/google/fonts) |
|---|---|---|---|
| Fraunces | Latin display | 300, 400, 400 italic | `ofl/fraunces/Fraunces[SOFT,WONK,opsz,wght].ttf`, `Fraunces-Italic[…].ttf` |
| Instrument Sans | Latin UI | 400, 500, 600 | `ofl/instrumentsans/InstrumentSans[wdth,wght].ttf` |
| Noto Naskh Arabic | Arabic display | 500, 600 | `ofl/notonaskharabic/NotoNaskhArabic[wght].ttf` |
| Noto Sans Arabic | Arabic UI | 400, 500, 600 | `ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf` |

Downloaded on 2026-10-15 from google/fonts `main` at commit
`94301472b4d809299b4775bc6502592b83dd6934` (download approved by the owner the same day).

Google publishes these families as variable fonts only. `tool/make_font_instances.py`
pins every axis and writes one static TTF per weight, so only the weights the spec uses
are shipped (about 1.4 MB in all). Fraunces is pinned to an optical size near the size it
is drawn at: 300 at opsz 96 (the hero time), 400 at opsz 40 (titles), 400 italic at
opsz 24 (prayer names, section titles); SOFT and WONK stay at 0. The other axes stay at
their defaults (wdth 100).

Note: Fraunces has proportional figures and no `tnum` feature, so the big times set in
Fraunces are not tabular (as on the design canvas). Instrument Sans and both Noto
families support `tnum`.
