# Cyber Theme — Design Decisions

## Visual Style

Inspired by neon-tube arcade buttons. Each cell has a glowing "neon tube" rounded
rectangle border drawn inset from the cell edge. The tube is the primary visual
indicator of the cell's lit state.

## Button State Model

| Axis     | Values            | Visual Signal                                    |
|----------|-------------------|--------------------------------------------------|
| **Lock** | Unlocked / Locked | Flush surface vs Sunken (inner shadow recess)    |
| **Lit**  | Lit / Unlit       | Subtle dark neon tint + bright tube vs Dark fill + dim tube |

### Four Base States

| State            | Appearance                                                   |
|------------------|--------------------------------------------------------------|
| Unlocked + Unlit | Dark slab, dim neon tube outline                             |
| Unlocked + Lit   | Subtle neon tinted fill, bright neon tube with bloom         |
| Locked + Unlit   | Dark slab with inner shadow recess, dim tube outline         |
| Locked + Lit     | Subtle tint with inner shadow recess, bright tube + glow     |

## Neon Tube

The neon tube is rendered by `_NeonTubePainter` using a `CustomPainter`.
It draws a rounded rectangle 13px inset from the cell edge:

**When lit** (5 paint passes):

1. Wide outer glow: thick blurred stroke (19px, blur 10) at 30% alpha
2. Medium glow: medium blurred stroke (13px, blur 4) at 50% alpha
3. Dark edge: thick 13px black stroke behind the tube to give it physical form
4. Core colored tube: sharp 9px stroke at full color
5. White-hot highlight: thin blurred white stroke (~3px) simulating glass reflection

**When unlit** (2 paint passes):

- Dark edge: black 13px stroke at 40% alpha
- Core tube: 9px stroke at 15% alpha (dim colored outline)

## Lit Fill Color

When lit, the cell fills with a subtle darkened version of the glow color:
`Color.lerp(cellDarkColor, glowColor, 0.2)`. This creates a beautiful, dark mid-tone
that immediately signals the lit state while preventing the color from turning into
a washed-out pastel. The black physical edge of the neon tube contrasts perfectly
against this subtle fill.

## Sunken Effect (Locked Cells)

Locked cells appear recessed into the board using inner shadow simulation:

- **Top-left gradient**: Dark shadow (black at 50% alpha) fading from top-left corner
  toward center, simulating the board lip casting shadow into the recess
- **Bottom-right gradient**: Subtle highlight (white at 4% alpha) on the far lip
- **Padlock Icon**: A subtle (`0.2` alpha white) `lock_outline_rounded` icon sits in the bottom-right corner.

## Interaction States (Unlocked cells only)

| State   | Visual Effect                              |
|---------|--------------------------------------------|
| Default | Normal scale (1.0)                         |
| Hovered | Subtle white edge highlight                |
| Focused | Subtle white edge highlight (tab navigator)|
| Pressed | 0.93× scale — button depresses             |

## Color Palette

| Color  | Hex       | Usage                    |
|--------|-----------|--------------------------|
| Board  | `#0D0E15` | Deep dark blue-black     |
| Cell   | `#161822` | Unlit cell surface       |
| Cyan   | `#00FFCC` | Default neon tube color  |
| Pink   | `#FF0055` | Red/error neon tube      |
| Blue   | `#0055FF` | Blue neon tube           |
| Yellow | `#FFDD00` | Yellow neon tube         |
| Purple | `#AA00FF` | Purple neon tube         |
| Green  | `#39FF14` | Green neon tube          |

## Animation

All state transitions use `AnimatedContainer` with:

- Duration: 150ms
- Curve: `easeOutCubic`
