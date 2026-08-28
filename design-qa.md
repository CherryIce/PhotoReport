# PhotoReport Engineering-Teal Design QA

## Comparison Target

- Source visual truth: `/Users/starburst/.codex/state/plugins/product-design/assets/photoreport-engineering-teal-home-report-approved.png`
- Implementation home screenshot: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-home-engineering-teal.png`
- Implementation project-detail screenshot: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-project-detail-engineering-teal.png`
- Implementation report-preview screenshot: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-report-preview-engineering-teal.png`
- Rendered detailed-PDF cover: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-detailed-pdf-cover-engineering-teal.png`
- Full-view home comparison: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-home-color-comparison.png`
- Full-view report comparison: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-report-color-comparison.png`
- Focused token/component comparison: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-token-components-comparison.png`

## Viewport And State

- Source board: 1536 x 1024 px.
- Simulator: iPhone 17 Pro, iOS 26.5, 402 x 874 logical px at 3x density; screenshots are 1206 x 2622 px.
- PDF: A4 595 x 842 pt, rendered at 144 DPI to 1190 x 1684 px.
- State: light appearance; one temporary project with three records covering pending, in-progress, completed, and high-priority semantics.
- Scope normalization: the selected design is a color-system board, not a pixel-identical layout redesign. Existing navigation, content hierarchy, cards, and workflow were intentionally preserved. Device chrome is runtime-owned and excluded from fidelity judgments.

## Full-View Comparison Evidence

- Home comparison places the source home direction and the implemented active-project home in one image. Primary teal, ink, canvas, surface, border, pending orange, completed green, and risk red visually follow the approved board.
- Report comparison places the source report direction and the generated native PDF cover in one image. The brand rule, ink hierarchy, soft information surface, and semantic metric colors match the approved roles.
- Project detail and report preview were additionally inspected at the simulator's native 3x capture size. No clipping, overflow, broken borders, unexpected gradients, or off-palette primary actions were visible.

## Focused Region Comparison Evidence

- The focused comparison places the approved swatch strip above the implemented PDF CTA, selected filters, status chips, issue badge, and floating action button.
- Exact semantic mapping is visible: pending `#AD5417`, in progress `#2465A8`, completed `#1F7650`, risk `#B7353D`; primary actions use `#0B6B63`; selected neutral surfaces use `#E7F0EE`.
- No additional focused image comparison was needed for annotation marks because their approved `#FF2D2D` value is locked by a token test and the annotation painter itself was unchanged apart from reading that token.

## Required Fidelity Surfaces

- Fonts and typography: existing PingFang-compatible Flutter hierarchy and iOS system PDF typography were preserved. No new wrapping or truncation appeared in the captured states.
- Spacing and layout rhythm: existing spacing, radii, card dimensions, and hierarchy were intentionally retained. The color-only implementation introduced no layout drift.
- Colors and visual tokens: all approved core and semantic values are centralized in `lib/ui/app_theme.dart`; Flutter surfaces, status components, annotation rendering, report preview, and native PDF use those values. The report preview gradient was removed in favor of the approved deep teal.
- Image quality and asset fidelity: no new static image assets were required. Report photos remain user-provided dynamic content; the simulator fixture intentionally had no photos, so the rendered empty-photo state is expected rather than a replacement asset.
- Copy and content: no production copy, routes, data model, filters, or workflow behavior changed.

## Findings

- No actionable P0, P1, or P2 differences remain within the approved color-system scope.
- Accessibility spot check: white on primary teal and primary ink on the canvas exceed WCAG AA for normal text; the new secondary text and semantic status values improve contrast over the previous palette. Status meaning continues to include text labels rather than color alone.

## Comparison History

1. Initial simulator pass found a P2 token drift: the extended floating action button and selected filter chips inherited a brighter seed-generated cyan outside the approved palette. Evidence: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-project-detail-before-token-fix.png`.
2. Fix: explicitly mapped ColorScheme containers, chip states, and the floating action button to the approved primary teal and soft emphasis surface.
3. Post-fix evidence: `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-project-detail-engineering-teal.png` and `/Users/starburst/PhotoReport/artifacts/design-qa/photoreport-token-components-comparison.png`. The earlier P2 drift is no longer present.

## Validation Notes

- Flutter analyze: passed.
- Flutter tests: passed, including exact color-token and theme-binding tests.
- iOS simulator build and launch: passed on iPhone 17 Pro, iOS 26.5.
- Native detailed PDF: generated successfully as a five-page A4 document and rendered with Poppler for visual inspection.
- Physical-device, dark-mode, and release/archive validation were not requested and were not run.

final result: passed

---

# Project list and project detail redesign QA — 2026-08-28

## Visual truth and implementation evidence

- Home reference: `/Users/starburst/PhotoReport/design/redesign-2026-08-28/home-project-list-redesign-v1.png`.
- Populated-detail reference: `/Users/starburst/PhotoReport/design/redesign-2026-08-28/project-detail-record-redesign-v1.png`.
- Empty-detail reference: `/Users/starburst/PhotoReport/design/redesign-2026-08-28/project-detail-empty-redesign-v1.png`.
- Home implementation: `/Users/starburst/PhotoReport/design/qa-2026-08-28/home-implementation-initial.png`.
- Populated-detail implementation after photo-path repair: `/Users/starburst/PhotoReport/design/qa-2026-08-28/project-detail-record-implementation-final.png`.
- Empty-detail implementation: `/Users/starburst/PhotoReport/design/qa-2026-08-28/project-detail-empty-implementation-initial.png`.
- Full-view comparisons: `/Users/starburst/PhotoReport/design/qa-2026-08-28/home-comparison.png`, `/Users/starburst/PhotoReport/design/qa-2026-08-28/project-detail-record-comparison-final.png`, and `/Users/starburst/PhotoReport/design/qa-2026-08-28/project-detail-empty-comparison.png`.

## Viewport and normalization

- Simulator: iPhone 17 Pro, iOS 26.5, 402 x 874 logical points; native captures are 1206 x 2622 pixels at 3x density.
- The generated references were resized with Lanczos filtering to 1206 x 2622 pixels and placed directly beside native Simulator captures with an 8-pixel ink divider.
- Device-owned iOS status chrome is present only in the implementation and is excluded from layout-fidelity findings.
- Verified states: populated home with formal and quick projects, formal empty detail at step 2 of 3, and quick single-record detail with an annotated real photo and an existing generated report.

## Mandatory comparison pass

| Surface | Result | Evidence |
| --- | --- | --- |
| Typography | Passed | Native PingFang rendering differs optically from the generated reference, while title, section, body, badge, metric, and CTA hierarchy remain equivalent and readable. No clipping or unintended truncation is visible. |
| Spacing and layout | Passed | Home cards expose mode before metrics; formal progress is visible in-card. Empty detail removes premature search, filters, status metrics, and PDF actions. Single-record detail places the record list before the secondary share section and removes the floating CTA. |
| Colors and surfaces | Passed | Primary teal, deep ink, canvas, semantic status colors, white cards, soft mode badges, borders, and disabled surfaces map to the approved app theme. No gradients or off-palette primary actions are present. |
| Images and icons | Passed | The populated-detail card renders the real annotated photo with the expected crop. Standard Material icons are consistently sized and aligned; no fabricated SVG, placeholder art, or stretched screenshot is used. |
| Copy and content | Passed | Quick/formal mode, formal step progress, empty guidance, filter disclosure, and share copy communicate the intended workflow without introducing formal inspection or legal claims. |
| States and interactions | Passed | Simulator navigation covered home to formal empty detail, back to home, then quick populated detail. Widget tests cover the single-record no-filter state, multi-record filter disclosure, and the one-CTA empty state. |
| Accessibility and resilience | Passed | Controls inherit the app's 48-point minimum target. Status is conveyed with labels and counts, not color alone. Widget coverage includes 402-point target width and a 320-point narrow home layout without overflow. |

## Findings and comparison history

1. The initial populated-detail capture showed a persistent thumbnail spinner. Database inspection confirmed that the stored absolute photo path referenced an earlier iOS app-container UUID while the same photo basename existed in the current container.
2. `PhotoStorage` now resolves stale container paths into the current `Documents/PhotoReport/photos` directory, `AppDatabase` persists the repaired path when loading records, and `AnnotatedPhoto` shows a bounded unavailable-image state if recovery is impossible.
3. The final populated-detail capture and combined comparison confirm that the annotated flower photo now renders correctly and the initial P2 runtime issue is resolved.
4. Residual P3 differences are limited to native iOS status chrome, native font/icon rasterization, slightly denser runtime cards, and live project ordering. These do not change hierarchy, functionality, or the approved design intent.

## Validation

- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 31 tests.
- iOS Debug build and launch: passed on iPhone 17 Pro Simulator.
- Final Simulator flow contains no visible Flutter overflow, exception surface, or unresolved loading state.
- Physical-device, dark-mode, Release/Archive, and store validation were not requested and were not run.

No P0, P1, or P2 design-fidelity or core-flow issue remains.

final result: passed

---

# Empty home and settings layout QA

## Visual target

- Empty-home reference: `/Users/starburst/.codex/generated_images/01a045f7-4bdc-7bd1-9548-abdd07b3cce1/exec-c0c6a734-3f13-436d-8890-6931ed454396.png` (853 x 1844).
- Settings-sheet reference: `/Users/starburst/.codex/generated_images/01a045f7-4bdc-7bd1-9548-abdd07b3cce1/exec-7e12eaf1-17b4-4279-85b2-91f7e35ef32d.png` (853 x 1844).
- User-annotated trailing-alignment target: `/var/folders/6h/fw9ps2896831sdwc108hy6dm0000gn/T/codex-clipboard-9a1087a5-b38a-4819-859a-0e7f817f0218.png` (1206 x 2622).
- Implementation viewport: iPhone 17 Pro Simulator, 402 x 874 logical points; screenshots are 1206 x 2622 pixels at 3x.
- User-reported pre-fix implementation: `/Users/starburst/Desktop/Simulator Screenshot - iPhone 17 Pro - 2026-08-28 at 10.17.00.png`.
- Empty-home implementation after safe-area correction: `/private/tmp/photoreport-empty-safe-area-final-1206x2622.png`.
- Settings-sheet implementation after trailing alignment: `/private/tmp/photoreport-settings-trailing-right-final-1206x2622.png`.
- Language-sheet implementation: `/private/tmp/photoreport-language-final-1206x2622.png`.

## Same-input comparisons

Both sides were normalized to 390 x 844 before comparison. The reference is on the left and the Simulator implementation is on the right.

- Empty home after correction: `/private/tmp/photoreport-empty-safe-area-comparison.png`.
- Bottom-notice focused comparison: `/private/tmp/photoreport-footer-safe-area-comparison.png`.
- Bottom-notice source / pre-fix / post-fix history: `/private/tmp/photoreport-footer-focus-three-way.png`.
- Settings open: `/private/tmp/photoreport-settings-comparison.png`.
- Settings trailing alignment before / after: `/private/tmp/photoreport-settings-trailing-full-comparison.png`.
- Settings trailing focused comparison: `/private/tmp/photoreport-settings-trailing-focus-comparison.png`.

## Review

| Surface | Result | Evidence |
| --- | --- | --- |
| Typography | Passed | Header hierarchy, body copy, step labels, CTA label, section labels, and settings rows retain the reference hierarchy. |
| Spacing and layout | Passed | The empty state is left-aligned, has one primary CTA, places the three-step path before it, and anchors the compact notice at the bottom. The settings sheet begins at the same normalized vertical position as the reference. |
| Color and surfaces | Passed | Engineering teal, deep ink, muted copy, soft teal icon wells, white sheet surface, separators, scrim, and canvas match the approved token direction. |
| Icons and rendering | Passed | Standard Material icons render sharply at native density; no fabricated image assets or stretched screenshots are used. |
| Copy | Passed | Empty-state guidance, local backup/restore explanations, language labels, and local-storage notice match the approved flow and have English localizations. |
| Interaction | Passed | The Simulator ellipsis opens Settings & data, Language opens its own selection sheet, and widget tests exercise switching to English. Backup and restore remain connected to the existing actions. |
| Responsive behavior | Passed | Widget tests cover the empty state at 320 x 568 and the populated app-bar create action at 320 x 720 without overflow or exceptions. |

## Iterations completed

1. The first empty-state build sat too high and wrapped the guidance inconsistently. Tall-screen spacing and explicit copy lines were introduced.
2. The first settings sheet occupied too much of the viewport. It was reduced to the reference's 38% height and its rows were compacted while retaining 48-point touch targets.
3. The final comparison exposed mismatched footer treatment and vertical rhythm. The empty-state notice now uses the reference divider treatment, and the settings footer/divider spacing was aligned so every row and the local-data note remain visible without scrolling on the target viewport.
4. User feedback identified a remaining P2 safe-area mismatch: the 10:17 Simulator capture placed the divider near 95.8% of screen height and clipped the notice into the bottom edge, while the reference divider is near 91.8%. Wrapping the notice in the native bottom `SafeArea` moved the complete footer upward by the iPhone inset. The post-fix focused comparison aligns the divider, icon, text baseline, and bottom breathing room with the reference.
5. The user-annotated settings capture identified a P2 trailing-alignment mismatch: the language value and chevron stopped near 72% of the sheet width instead of using the right edge. Replacing the loose `Flexible` trailing value with an intrinsically sized, width-capped value lets the title consume the remaining row width and places the value/chevron at the same right edge as the backup and restore rows. Widget coverage now asserts the language chevron and value remain right-aligned at 320-point width.

## Residual differences

- P3: The implementation includes the real iOS status area while the generated empty-state reference omits it.
- P3: Native Flutter text rasterization and Material glyph geometry differ slightly from the generated mock, without changing hierarchy, spacing intent, or interaction.

No P0, P1, or P2 fidelity issues remain. The Simulator log contains no Flutter exception, overflow, or fatal entry for the verified flow.

final result: passed
