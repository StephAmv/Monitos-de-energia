---
name: Aether Grid Twin
colors:
  surface: '#031427'
  surface-dim: '#031427'
  surface-bright: '#2a3a4f'
  surface-container-lowest: '#000f21'
  surface-container-low: '#0b1c30'
  surface-container: '#102034'
  surface-container-high: '#1b2b3f'
  surface-container-highest: '#26364a'
  on-surface: '#d3e4fe'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#d3e4fe'
  inverse-on-surface: '#213145'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#ffb95f'
  on-secondary: '#472a00'
  secondary-container: '#ee9800'
  on-secondary-container: '#5b3800'
  tertiary: '#ffb3ad'
  on-tertiary: '#68000a'
  tertiary-container: '#ff7a73'
  on-tertiary-container: '#79000e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#031427'
  on-background: '#d3e4fe'
  surface-variant: '#26364a'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-lg: 1.5rem
  margin: 1rem
  margin-lg: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system establishes a high-precision, operations-grade interface engineered for critical infrastructure oversight and energy digital twins. It caters to grid dispatchers, industrial system operators, and simulation engineers who monitor high-density telemetry streams for sustained intervals. 

The aesthetic is **Modern Technical Minimalism** paired with tactical data clarity:
- **Atmospheric Anchor:** A deep nocturnal base that prevents eye fatigue while providing high functional contrast against dynamic signals.
- **Instrument Precision:** Avoids decorative ornamentation, heavy glass blurs, or visual skeuomorphism. Depth is communicated strictly via tonal surface shifts and disciplined structural framing.
- **Operational Focus:** Visual noise is minimized so that anomalies and operational state transitions immediately command attention.

## Colors
The color architecture is built entirely around dark-mode operational discipline, leveraging specific midnight navy tiers for surface stratification and strict semantic status channels.

### Surface Architecture
- **Canvas Base (`#060d1a`):** The primary view substrate, grounding the entire operational suite.
- **Card / Surface Default (`#0a1526`):** Standard container background for metrics, graphs, and modular widgets.
- **Raised / Interactive Surface (`#0e1e38`):** Hover states, elevated panels, modal drawers, and nested utility strips.
- **Border & Dividers (`#1e2f4d`):** Clean, crisp bounding lines that delineate modules without high-contrast visual friction.

### Semantic Telemetry Status
- **Normal / Operational (`#10b981` - Emerald):** Nominal performance, stable twin synchronicity, and verified metrics.
- **Estimación / Anticipada (`#f59e0b` - Warm Amber):** Predictive states, model extrapolations, and non-blocking warnings.
- **Vigente / Falla / Causante (`#ef4444` - Vivid Crimson/Coral):** Live anomalies, root-cause nodes, and critical excursions.
- **Sin Telemetría / Incierto (`#64748b` - Slate Blue):** Missing data feeds, disconnected sensor streams, or uncalibrated nodes.

## Typography
The system employs **Inter** for high legibility across descriptive interfaces, titles, and dense spatial layouts, paired with **JetBrains Mono** for strictly structured telemetry readings, timestamps, sensor IDs, and coordinate outputs.

- **Tabular Figures:** All numeric data, including tabular views and rapid-refresh readouts, must mandate tabular figure alignment (`font-variant-numeric: tabular-nums`) to prevent horizontal jitter during live streaming.
- **Hierarchy:** Primary titles remain restrained in scale to preserve dashboard density; metric figures and sensor names lean on weight and monospace precision rather than massive font sizing.
- **Text Color Hierarchy:** High-emphasis copy defaults to `#f8fafc`, medium operational descriptors to `#94a3b8`, and low-emphasis hardware/timestamp metadata to `#64748b`.

## Layout & Spacing
The layout model is anchored by a dense, structured **fluid grid** optimized for multi-pane control rooms and widescreen operator cockpits.

- **Grid System:** Standard 12-column grid scaling up to 24 columns for ultra-wide command surfaces. Gutters maintain `1rem` (16px) on viewports below 1440px and scale to `1.5rem` (24px) for expansive monitors.
- **Outer Canvas Margins:** Maintained uniformly at `1rem` on compact displays, expanding to `1.5rem` for control console stations to maximize usable real estate without visual clipping.
- **Reflow & Responsiveness:** Modular card containers collapse into dual or single stacked columns on narrower tablet surfaces. Critical telemetry banners and fault notification bars detach into floating dock configurations on viewports under 1024px.
- **Rhythm:** Spacing follows a strict 4px/8px mathematical base. Internal component padding favors compact arrangements (`space-sm` to `space-md`) to ensure critical telemetry remains above the fold.

## Elevation & Depth
Elevation in this system eschews heavy physical drop shadows in favor of **Tonal Layering** and **Subtle Structural Borders**, keeping data representations crisp and free of visual dirt.

- **Level 0 (Floor Canvas):** Solid background color `#060d1a`.
- **Level 1 (Default Containers & Tiles):** Solid `#0a1526` encased by a 1px uniform structural border in `#1e2f4d`.
- **Level 2 (Active Focus & Flyouts):** Solid `#0e1e38` bordered with `#1e2f4d` and supplemented with a concentrated, low-bleed ambient shadow: `box-shadow: 0 8px 24px -4px rgba(2, 6, 17, 0.6)`.
- **Level 3 (Modal Alerts & Overrides):** Elevated panel fill `#0e1e38` reinforced with subtle status-tinted perimeter glow (e.g., `0 0 0 1px rgba(239, 68, 68, 0.4)` during active grid trip scenarios).

## Shapes
A controlled, technical **Soft (`1`)** shape language delivers refined engineering ergonomics without the casual, consumer-app appearance of rounded pill geometries.

- **Base Radii:** Standard cards, inputs, and modular nodes use `0.25rem` (4px).
- **Secondary Surfaces (`rounded-lg`):** Main panels, diagnostic overlays, and alert banners leverage `0.5rem` (8px).
- **Modal Containers (`rounded-xl`):** Dedicated inspection frames and floating twin controllers utilize `0.75rem` (12px).
- **Status Indicators:** Micro indicator nodes and telemetry state dots maintain pure geometric circles (`50%`), standing out clearly against the angular rectilinearity of the surrounding dashboard.

## Components

### Buttons & Controls
- **Primary Action:** Solid `#10b981` background with `#060d1a` bold typography for unambiguous confirmation. Hover shifts to `#059669`.
- **Secondary / Operational:** Background `#0e1e38`, border 1px `#1e2f4d`, text `#f8fafc`. Hover triggers a border shift to `#3b82f6` or semantic status colors.
- **Destructive / Trip:** Background `#ef4444`, text `#ffffff`. Reserved exclusively for system shutdowns, manual circuit trips, or state overrides.

### Status Chips & Badges
- Constructed with a 10% opacity semantic fill, a 1px solid border matching the base token at 30% opacity, and bright semantic text:
  - *Normal:* `#10b981` text, `rgba(16, 185, 129, 0.1)` background, `rgba(16, 185, 129, 0.3)` border.
  - *Estimación:* `#f59e0b` text, `rgba(245, 158, 11, 0.1)` background, `rgba(245, 158, 11, 0.3)` border.
  - *Vigente / Falla:* `#ef4444` text, `rgba(239, 68, 68, 0.12)` background, `rgba(239, 68, 68, 0.4)` border.
  - *Sin Telemetría:* `#64748b` text, `rgba(100, 116, 139, 0.1)` background, `rgba(100, 116, 139, 0.25)` border.
- Integrated pulsing indicator dot (6px) aligned to the left of the label when state is actively streaming or updating live.

### Telemetry Cards & Metric Blocks
- Structured on `#0a1526` with a uniform 1px `#1e2f4d` border.
- Cards feature a dedicated header bar displaying node identification in `label-sm`, an upper-right semantic chip, and a prominent primary measurement value rendered in high-contrast `#f8fafc`.
- Sparklines and mini trends within cards inherit semantic stroke colors without area fills to prevent visual clutter.

### Input Fields & Selectors
- Inputs utilize an inset background of `#060d1a`, surrounded by a 1px `#1e2f4d` border. Text renders in `label-md` or `body-md` in `#f8fafc`.
- Focus states transition the border to `#10b981` (or contextual filter color) with no drop shadow blur.

### Lists & Data Grids
- Alternating rows avoid striped zebra fills; row separation is maintained strictly with 1px `#1e2f4d` bottom borders.
- Hovering a row highlights the surface to `#0e1e38` with an instantaneous 100ms transition.
- Monospace typography (`JetBrains Mono`) governs all data table cells handling numerical units (MW, kV, Hz, timestamps).

### Checkboxes, Toggles & Radios
- Unselected boxes feature an empty fill with `#1e2f4d` borders.
- Active state renders a crisp `#10b981` solid fill with an `#060d1a` check glyph, creating immediate verification against the midnight backdrop.