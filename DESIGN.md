# RuralCare — App Design Guide

## 1. Purpose and scope

Use this document as the visual and interaction brief when implementing RuralCare. This task produces a design specification only; it does not authorize starting or scaffolding the app.

The intended app feels **calm, minimal, beautiful, and easy to trust**. Make healthcare coordination understandable, not visually complicated. Show the next useful action rather than every possible feature.

Product behavior comes from `MASTER_SPECIFICATION_RuralCare.md`, `USER_FLOWS_RuralCare.md`, and `BACKEND_SPEC_FLUTTER_FIREBASE_PYTHON.md`. Target Flutter; do not follow the conflicting Next.js direction in the PRD.

The specifications name Stitch as the approved visual source. No Stitch assets are included in this repository. This guide proposes a consistent design system, not a reproduction of unseen screens. Preserve approved screens when supplied unless they conflict with product requirements or accessibility.

## 2. Creative direction

**A quiet care companion, not a hospital management spreadsheet.**

- Warm off-white backgrounds, white surfaces, deep navy text, restrained blue accents.
- Generous breathing room, soft corners, clear typography, almost no shadows.
- One primary action per section. Prefer fewer, well-composed elements to crowded dashboards.
- Use teal sparingly for supportive details. Reserve amber for attention and red for critical conditions.
- Plain language: “Your next appointment,” “Waiting to sync,” “View referral.”
- Human details through greetings, helpful explanations, and clear next steps—not decorative graphics.

Avoid glassmorphism, large gradients, excessive pills, neon colors, decorative charts, dense icon grids, oversized hero sections, and cards nested inside cards. Do not use emoji as interface icons.

## 3. Design tokens

### Color

| Token | Value | Use |
|---|---|---|
| canvas | `#F7F9FC` | Screen background |
| surface | `#FFFFFF` | Cards, sheets, navigation |
| surface-subtle | `#EEF3F8` | Secondary sections, disabled fills |
| text-primary | `#172B4D` | Titles and body text |
| text-secondary | `#52637A` | Supporting text |
| border | `#DCE4ED` | Decorative dividers and card boundaries |
| input-border | `#7B8BA0` | Visible form control boundaries |
| primary | `#2457C5` | Main actions and selected navigation |
| primary-pressed | `#1B4399` | Pressed primary buttons |
| primary-soft | `#EDF3FF` | Selected surfaces; use primary text |
| teal | `#147D78` | Supporting emphasis |
| teal-soft | `#EAF7F4` | Supporting surface |
| success | `#216E4A` | Confirmed successful state |
| success-soft | `#ECF7EF` | Success background |
| warning | `#8A5300` | Attention text/icon |
| warning-soft | `#FFF5DF` | Warning background |
| critical | `#B42318` | Emergency and critical state |
| critical-soft | `#FFF0ED` | Critical background |
| focus | `#2457C5` | Keyboard focus outline |

Use white text on solid primary or critical buttons. On pale status backgrounds, use the corresponding dark status color. Never communicate status by color alone. Verify actual text and control contrast in implementation; tokens alone do not guarantee accessible combinations.

### Typography

Use **Noto Sans**, with Noto Sans Devanagari coverage for Hindi and Marathi. No more than three weights: 400, 500, 600.

| Style | Size / line height | Weight |
|---|---|---|
| Page title | 28 / 36 | 600 |
| Section title | 20 / 28 | 600 |
| Card title | 17 / 24 | 600 |
| Body | 16 / 24 | 400 |
| Button / prominent label | 16 / 24 | 600 |
| Supporting text | 14 / 22 | 400 |
| Navigation label | 12 / 18 | 500 |
| Measurement value | 28 / 36 | 600 |

Use sentence case. Avoid all-caps labels and excessive letter spacing. Keep clinical instructions at body size. Support system text scaling without clipping; reflow rather than shrinking text.

### Layout and shape

- Spacing scale: **4, 8, 12, 16, 24, 32, 48** logical pixels.
- Phone horizontal padding: **20**; use **16** below 360 width.
- Section gap: **24–32**. Card padding: **16–20**. Related elements: **8–12**.
- Card radius: **16**. Inputs/buttons: **12**. Bottom sheets: **24** at top corners.
- Small status labels: radius **6**, not oversized pill shapes.
- Default cards: white fill and 1-pixel decorative border; no shadow.
- Floating sheets/navigation may use one subtle shadow: black at 6%, blur 20, vertical offset 4.
- Main controls: minimum **48 × 48** touch target; primary buttons minimum height **52**, expandable for wrapped text.
- Icons: consistent outlined family, 24 size and comparable stroke weight. Use filled icons only for selected states where helpful.

## 4. Responsive application shell

### Phone: below 600

Single-column layout, safe-area aware. Keep long content naturally scrollable. Place primary actions after relevant content or in a bottom action area that does not cover it. Forms must remain usable with the keyboard open.

Patient bottom navigation is fixed:

**Home | Appointments | Records | Referrals | Profile**

Always show icon and label. Selected item uses blue text/icon and a small pale-blue selection background. Medicines, diagnostics, teleconsultation, and emergency are not extra bottom tabs.

### Tablet: 600–1023

Use a navigation rail when the content benefits from it. Patient content remains focused and readable. Clinical queues can use two panes only when both remain usable at large text sizes.

### Desktop: 1024 and above

Use a 232-wide sidebar with a compact product mark and labeled destinations. Content max width: 1200, with 32 outer padding. Reading/forms max width: 720. A patient dashboard should not stretch into a wide analytics console.

Clinical screens may use a 320-wide queue alongside a flexible patient workspace. Collapse to list → detail on smaller widths.

### Shared header

Show a concise page title, relevant facility context, and notification access. Use a back button on nested screens. Do not repeat branding on every screen. Show language access during onboarding and in Profile; provide a discreet shortcut on patient Home.

## 5. Core components

### Buttons

- Primary: solid blue, white label; one dominant action in a local context.
- Secondary: white/transparent fill, visible boundary, blue label.
- Tertiary: text action with a full touch target.
- Critical: solid red only when the action warrants it; not for ordinary cancellation.
- Loading: retain label and width, add spinner, prevent duplicate submission.
- Disabled: clearly unavailable with a nearby reason when not obvious.
- Hover: subtle surface change. Pressed: darker fill, no bouncing or dramatic scaling.

### Forms

Persistent labels above inputs; placeholders are examples, not labels. Minimum input height 52. Use generous multiline fields and appropriate keyboard types. Mark optional fields rather than decorating every required field.

Show helper text below the field. On validation failure, keep input, show a specific inline error with an icon, and move focus to the first invalid field on submission. Explain date formats. OTP entry must support paste/autofill and an accessible single-code reading order.

### Cards and rows

A card groups a meaningful task, not every piece of text. Use a clear heading, one or two supporting lines, and a predictable action. Related records are usually simple rows separated by spacing or dividers.

Interactive cards need visible focus and clear accessible names. Avoid nested tap targets with ambiguous behavior. Prefer a trailing “View details” action where a row contains other controls.

### Status labels

Use short text plus an icon where needed: “Confirmed,” “Pending sync,” “Needs review.” Keep visit, clinical, delivery, and connectivity statuses distinct. Never label missing measurements as “Normal.”

### Sheets and dialogs

Use bottom sheets on mobile for short choices or filters, dialogs on wider screens. Give every sheet a title and explicit close action. Full workflows use pages, not deeply nested sheets. Confirm irreversible actions; avoid confirmation dialogs for harmless navigation.

### Feedback

Inline feedback for field or section problems. Banners for persistent connectivity or workflow issues. Snackbars only for brief, noncritical confirmations. Critical alerts remain visible until handled; never rely on a temporary toast.

## 6. Patient screens

### Onboarding

One decision per step: welcome → language → role → mobile/OTP → basic profile → healthcare area → account created/RuralCare ID.

Use a small product mark, a short heading, one-sentence explanation, and a bottom Continue action. Avoid marketing carousels and large illustrations. Preserve prior entries when going back. Role selection does not itself grant professional access.

### Home

Visual hierarchy:

1. Compact greeting and healthcare area, notification button.
2. **Next care** card: the most relevant appointment, follow-up, or referral and one main action.
3. Quick actions: a compact two-column arrangement for Book appointment, Teleconsultation, Find facility, Medicines, Diagnostics. Do not stretch the last tile awkwardly; a simple full-width final row is acceptable.
4. Health snapshot: recent consultation and latest prescription/report as quiet rows.
5. Active follow-up/referral only when relevant and not duplicating Next care.
6. Visible, restrained **Emergency help** action with red icon/text—not a large permanent alarming banner.

Example composition (illustrative labels, not live data):

```text
Good morning                         Notifications
Your healthcare area

┌ Your next appointment ──────────────────┐
│ Clinician / service                     │
│ Date · time · facility                  │
│ [ View appointment ]                    │
└─────────────────────────────────────────┘

How can we help?
[ Book appointment ] [ Teleconsultation ]
[ Find facility    ] [ Medicines        ]
[ Diagnostics                           ]

Your health
Recent consultation                  View
Latest prescription                  View

Emergency help

Home  Appointments  Records  Referrals  Profile
```

If no next-care item exists, replace it with a useful invitation to book or find care. Do not invent appointments or measurements.

### Appointments

Default to upcoming appointments; provide a quiet Past view. Each row shows date/time, clinician/service, facility, and status. Booking follows facility → doctor → date/time → review → confirmation. Review exposes editable sections. Confirmation appears only after the relevant system acknowledgement.

### Records

Summary first. Use simple filters for consultations, prescriptions, diagnostics, and vitals. Show date, type, clinician/facility, and a short title. Details prioritize clinical content over decorative framing. Keep attachments clearly labeled with file type and availability.

### Referrals

Show receiving facility, reason summary, current stage, and next action. Detail uses a vertical timeline: Created → Sent → Accepted → Visit → Completed → Follow-up. Add optional transport stages only when actually supported. Rejected/unavailable states must provide a clear next step. A pending milestone must not look completed.

### Teleconsultation

Present doctor/service selection and consultation details simply. Explain consent before optional record sharing. Waiting room shows actual connection state, preparation guidance, and support access—not invented wait estimates. During calls, video is primary; captions/transcript are collapsible. Label transcript as a communication aid, not the official record. Show audio fallback or retry only when available.

### Medicines and diagnostics

Search first, then simple results with facility availability and last-updated information. Distinguish “Unavailable” from “Information unavailable.” Do not invent inventory quantities, preparation instructions, or substitutions. Separate test information, availability, and reports.

### Profile

Group personal details, language, healthcare area, next of kin, sharing preferences, and account actions. Prefer straightforward list rows. Display RuralCare ID without implying a government-issued identity.

### Emergency help

Use a focused page with a clear title, brief explanation of what the app can actually do, explicit location-sharing choice when relevant, and a prominent action. Display real states such as queued, sent, failed, unavailable, or acknowledged. Never imply ambulance dispatch or guaranteed help without a functioning integration. Do not invent helpline numbers. Offline failure must be prominent and actionable.

## 7. Professional workspaces

Professional interfaces use the same visual system with more information density, not a different product aesthetic. Prefer clear lists to walls of metric cards.

| Role | Suggested primary destinations | Main workspace |
|---|---|---|
| Health worker | Today, Patients, Follow-ups, Alerts, Profile | Prioritized tasks and patient screening |
| Doctor | Queue, Patients, Monitoring, Follow-ups, Profile | Patient summary and consultation |
| Facility staff | Overview, Queue, Referrals, Services, Profile | Intake and operational coordination |
| Admin | Overview, Users, Facilities, Audit, Settings | Approvals and system operations |

These role-specific destinations are proposed layouts, not an expansion of patient navigation. Show only permitted workflows. A facility is an organization; show an explicit facility switcher for users with multiple memberships.

### Health worker

Today prioritizes emergency, high risk, overdue follow-up, due follow-up, then routine. Each task shows patient identity, reason, location/context where appropriate, and one next action. Screening uses short sections: vitals → symptoms/history → review → triage result. Show unsynced work visibly without blocking unrelated local capture.

### Doctor

Keep patient name and essential context above the clinical workspace. Summary precedes detailed history. Consultation sections: concern, vitals, history, assessment, care plan. Clearly separate saved drafts from completed consultations. Care-plan actions include prescription, diagnostics, referral, and follow-up without overwhelming the main form.

### Facility staff

Use a compact operational summary, current queue, and actionable referrals. Inbound referral detail presents patient summary, requested capability, and accept/reject actions. Availability editing shows freshness and distinguishes service availability from missing information.

### Admin

Prioritize pending approvals and actionable system issues over vanity metrics. Use searchable, filterable tables on desktop and labeled rows on mobile. Keep role/facility changes explicit and show the result. Do not imply administrative access automatically grants clinical privileges.

## 8. Monitoring and maternal care

Treat these as later-phase modules unless separately requested for implementation.

- Show heart rate, SpO₂, and temperature with unit, measurement time, source, and quality/sync state.
- Use calm values and sparklines only when real data exists. Provide readable chart axes, date range, textual summary, and access to underlying readings.
- Stale, missing, or invalid data displays a clear label, not a reassuring status.
- Alert detail shows the triggering event, rule explanation supplied by the backend, notification state, escalation history, and permitted next actions.
- Visually distinguish “Sent,” “Delivered,” and “Acknowledged.”
- Device status includes connected/disconnected, last reading, and battery only when reported.
- Maternal overview highlights next ANC/follow-up, pregnancy timeline, and clinician-provided risk context without exposing unnecessary detail on shared dashboards.

Do not invent clinical thresholds or diagnose from a color/chart. Decisions remain clinically validated and backend-controlled.

## 9. Required states for every relevant screen

| State | Presentation |
|---|---|
| Loading | Stable-layout skeletons; avoid flashing or aggressive shimmer |
| Empty | Small icon, clear explanation, one useful next action |
| Recoverable error | Plain-language message, preserved work, Retry |
| Offline | Persistent quiet banner with offline capability explained |
| Pending sync | Inline label on affected records; distinguish local save from server save |
| Sync failed | Persistent record-level warning and supported retry action |
| Stale data | Last-updated timestamp and explicit freshness warning |
| Permission unavailable | Clear explanation; no inaccessible data visible underneath |
| Successful completion | Brief confirmation tied to actual acknowledgement |
| Partial notification failure | Recipient/channel outcome and available next step |

Connectivity must never be represented as a clinical state. Do not show an offline emergency event as successfully delivered.

## 10. Motion and interaction

- Button/hover/focus transitions: 120–160 ms.
- Page and sheet transitions: 180–240 ms with gentle ease-out.
- Prefer subtle fade/translation over zooms and bounce effects.
- No pulsing clinical warnings, autoplay decorations, or celebratory confetti.
- Honor reduced-motion preferences and remove nonessential animation.
- Preserve scroll position when returning from details; keep filter and form state predictable.

## 11. Accessibility and localization

Target WCAG 2.2 AA behavior where applicable. Verify normal text contrast at least 4.5:1 and meaningful control boundaries/icons at least 3:1 against adjacent colors.

Provide semantic headings, logical focus order, accessible control labels, visible keyboard focus, and screen-reader announcements for meaningful updates. Charts need text alternatives. Never make swipe, hover, or color the only means of interaction.

Normal screens use the chosen language: English, Hindi, or Marathi—not all three simultaneously. Allow roughly 30–40% label expansion and variable-height controls; test actual translations. Avoid truncating medicine names, critical instructions, or clinical values. Localize dates and explanatory text while keeping clinical units unambiguous. Support 200% text scaling with usable reflow.

## 12. IDE implementation guidance

When implementation is separately authorized:

1. Read the product specifications and this guide before creating screens.
2. Use a shared Flutter theme with centralized color, spacing, shape, and typography tokens; do not scatter hard-coded styles.
3. Reuse app shell, button, form field, status label, record row, empty state, connectivity banner, and timeline components.
4. Build consistent navigation and real states before adding decorative detail.
5. Keep business rules and authorization out of UI styling logic. Display backend-provided clinical and delivery states faithfully.
6. Preserve approved Stitch screens when supplied, reconciling them with accessibility and product requirements.
7. Use clearly labeled synthetic data only for demos; do not present it as live patient/facility information.
8. Do not add packages, application scaffolding, or backend code solely because this design file exists.

## 13. Design acceptance checklist

- [ ] The first screen feels calm, spacious, and immediately understandable.
- [ ] Patient navigation has exactly the five prescribed destinations.
- [ ] Each screen clearly shows its purpose and primary next action.
- [ ] Shared components, spacing, typography, and colors remain consistent across roles.
- [ ] No crowded metric dashboard, unnecessary gradient, or nested-card clutter.
- [ ] Phone, tablet, and desktop layouts adapt instead of simply stretching.
- [ ] Large text, keyboard navigation, screen readers, and all three languages remain usable.
- [ ] Loading, empty, failure, offline, stale, and pending-sync states are designed.
- [ ] Clinical severity, connectivity, and notification delivery are visually distinct.
- [ ] No invented clinical thresholds, integrations, dispatch promises, or delivery confirmations.
- [ ] No application implementation begins without a separate request.
