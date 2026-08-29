# Purchases

Checklist for buying. **Reasoning lives in `MASTERPLAN.md` §09** — this file is the
part you carry to the shop. Fill in `Paid` as you go; the gap between Target and Paid
is the thing worth knowing a year from now.

Prices re-checked **30 Aug 2026**. Two global shortages are in effect (DRAM and NAND,
both driven by AI datacenter demand), so anything with memory or flash in it is
2–4× the price this plan originally assumed. Forecasts run past 2028 — don't wait it out.

R6: **buy what unblocks the next phase, nothing else.** The exception is AliExpress
(3–6 weeks plus customs) — order those one phase early. Nothing before H-05 is AliExpress.

---

## Buy next — H-01 → H-05

| ✓ | Item | Where | Target ₹ | Paid ₹ |
|:-:|---|---|--:|--:|
| ✅ | Domain `akhildhyani.me` | GitHub Student Developer Pack | **0** | 0 |
| ⬜ | **2 TB portable external HDD** | Amazon.in, Flipkart | 5,500–7,000 | ____ |
| ⬜ | 2.4–2.8″ SPI TFT, ILI9341 320×240 | Robu, Sunrom, Amazon.in | 600–1,200 | ____ |
| ⬜ | WS2812B 5 m 60 LED/m strip | Robu, Amazon.in | 1,200–2,000 | ____ |
| ⬜ | 5 V 10 A SMPS | Robu, Amazon.in | 700–1,200 | ____ |
| ⬜ | 74AHCT125 level shifter | Sunrom, Evelta | ~50 | ____ |
| ⬜ | Bench kit — see below | Robu, Sunrom, Amazon.in | 2,500–4,500 | ____ |

**≈ ₹10,600–16,100 total.**

**Checked against live listings, 30 Aug 2026:**

- **Buy the strip on Amazon (₹1,252), not Robu (₹2,759).** Robu's is IP67 waterproof —
  worse indoors, not better: the silicone sleeve traps heat and makes cutting and
  soldering to the pads awkward, for sealing a bedroom wall will never need.
- **Pay up for the Mean Well LRS-50-5 (₹1,499) over the ₹799–899 generics.** It runs
  24/7, fanless, under continuous load from 300 LEDs. No-name 50 W bricks are where
  this kind of build actually fails.
- **Robu's own listing says 50 mA/LED**, so worst case is 300 × 50 mA = **15 A = 75 W**
  against a 50 W supply. Fine for every state in H-05's table — still cap brightness.
- **The display ships as either ILI9341 or ST7789, seller's choice.** Set the matching
  driver in TFT_eSPI `User_Setup.h`; a white screen on correct wiring is almost always
  this. It is 3.3 V IO, so no level shifting — unlike the strip.
- **Every 74AHCT125 Robu stocks is surface-mount** (SO-14, TSSOP-14, DHVQFN-14). H-05 is
  the first time you hold an iron; do not learn on 0.65 mm pitch. Search `74AHCT125N`
  for the DIP-14 part, or take the diode route below. Ignore the ₹2,924 Amazon listing
  for a ₹60 chip.
- **Set your Amazon delivery address to Jodhpur before ordering.** It currently defaults
  to Noida.

**Three things that are easy to get wrong:**

1. **HDD, not SSD.** The plan originally said "1 TB external SSD". Under the NAND
   shortage that's ₹10–18k; a 2 TB HDD is ~₹7k. `restic` writes sequentially, overnight,
   unattended — SSD latency buys nothing. Twice the capacity for a third of the money.
2. **Move DNS to Cloudflare before H-01.** The Student Pack `.me` is registered at
   Namecheap, whose API needs 20 domains / $50 balance / $50 spent in 2 years. Without
   it Caddy cannot answer a DNS-01 challenge. Keep Namecheap as registrar, point the
   nameservers at Cloudflare (free), use Caddy's Cloudflare module.
3. **The 10 A supply cannot do full white.** 300 LEDs × 60 mA = 18 A worst case against
   50 W of supply. Fine for every state in H-05's table — just cap brightness in
   firmware so a stray all-white command never asks for it.

---

## The rack — buy once, keep forever

**Boltless slotted-angle steel rack**, roughly **2 ft wide × 1.5 ft deep × 5 ft high,
4–5 shelves.** ₹2,500–5,000 from a local fabricator, ₹5,000–9,500 for a branded
flat-pack on Flipkart/Amazon. Plus ~₹500 for a plywood or HDF board cut to one shelf.

**Size it so one shelf sits at ~75 cm — that shelf is the workbench.** Slotted angle
adjusts every 1.5 inches, so this costs nothing extra and turns one purchase into both
the equipment rack and the soldering bench you need from H-05 onward.

**Why this and not a 10″ mini rack:** none of this lab's hardware is rack-mount — a
laptop, a USB HDD, a mini-PC, a switch. A DeskPi RackMate T1 lands at ₹12–18k after
customs and still needs a shelf or a 3D print for every single item, and gives no work
surface at all. It is the aesthetic answer to the smallest part of the problem.

**Why it lasts to H-11:**

- **Open frame = ventilation.** MAGI runs 24/7. A closed cabinet cooks it; this doesn't.
- **Extends instead of being replaced.** Slotted angle is a warehouse system — buy more
  angle and another shelf, make it taller or wider. It grows into H-10's second machine
  and switch rather than being outgrown by them.
- **Flat-packs.** You will change rooms at least twice before H-11. It disassembles with
  no special tools and no lost parts.
- **Locally repairable.** Every hardware market in India cuts and sells this. No import,
  no lead time, no single vendor.

**Two things that are easy to get wrong:**

1. **Never work on a powered board directly on a bare steel shelf.** It is a conductive
   surface across every exposed pad underneath — the classic way to short a project you
   just finished. The work shelf gets ply or HDF, then the silicone mat, always.
2. **Heat and drives don't share a shelf.** Keep the soldering iron and the 5 V LED
   supply off whatever shelf holds the backup HDD and MAGI.

Worth adding at the same time: a **vertical laptop stand** (₹300–800) so MAGI stands on
its edge rather than lying flat — roughly halves its footprint, and keeps the bottom
intake clear as long as it isn't pushed against a wall. A **power strip cable-tied to an
upright**, and **velcro ties** rather than zip ties, so re-cabling in H-10 isn't a
scissors job.

| ✓ | Item | Where | Target ₹ | Paid ₹ |
|:-:|---|---|--:|--:|
| ⬜ | Boltless slotted-angle rack, 2×1.5×5 ft, 4–5 shelves | Local fabricator, Flipkart, Amazon.in | 2,500–5,000 | ____ |
| ⬜ | Ply/HDF board cut to one shelf — the work surface | Local timber shop | ~500 | ____ |
| ⬜ | Vertical laptop stand for MAGI | Amazon.in | 300–800 | ____ |
| ⬜ | Power strip + velcro cable ties | Amazon.in | 400–800 | ____ |

---

## Deferred — with the trigger that un-defers it

| Item | ₹ | Buy when |
|---|--:|---|
| 2 × 8 GB DDR4-3200, matched pair | 12,000+ | **H-08.** Nothing before it needs the bandwidth. Shortage; expect to pay more later, not less. |
| 7.5″ e-paper 800×480 + driver | 7,000–9,000 | Once the SPI TFT prototype has told you which six numbers belong on a wall. |
| Gigabit switch + Cat6 | 1,500–2,300 | **H-10**, second machine. One wall port, one machine, until then. |
| RTL-SDR Blog V3 + dipole | 4,800–5,500 | **H-06.** |

---

## Bench kit

**Bold = needed for H-05.** The rest is genuinely later — this list is meant to stay
useful for years, not to be bought in one order. Soldering iron already owned.

- **Soldering** — **chisel tip 2.4 mm**, **fine conical tip**, **63/37 rosin-core 0.8 mm**,
  **flux pen or paste**, **brass tip cleaner** · tip tinner, desoldering braid, solder sucker
- **Holding** — **helping hands or small PCB vise**, **heat-resistant silicone mat** · ESD strap
- **Cutting & gripping** — **flush cutters**, **wire strippers**, **fine needle-nose pliers**,
  **tweezers, straight + curved**
- **Measurement** — **multimeter** (continuity beeper matters most) · USB power meter ·
  8-channel logic analyser (~₹500, disproportionately useful) · oscilloscope, defer
- **Wire & interconnect** — **22 AWG stranded silicone for power**, **JST-SM 3-pin pairs**,
  **Dupont jumpers M-M / M-F / F-F** · 22 AWG solid, screw terminals, DC barrel jacks, ferrules
- **Insulation & mechanical** — **heat-shrink assortment** · kapton tape, electrical tape,
  zip ties, adhesive cable clips, M3 standoff/screw kit
- **Prototyping** — **half + full breadboard**, **male and female pin header strips** · perfboard
- **Passives & semis** — **resistor assortment E12 ¼ W**, **capacitor assortment incl.
  1000 µF/16 V**, **74AHCT125** · IRLZ44N logic-level MOSFETs, 1N4148/1N4007, LEDs, BC547
- **Power & safety** — **inline fuse holder + fuses on the 5 V rail**, **safety glasses** ·
  small fan for solder fumes · bench PSU, later
- **Storage** — compartment organiser, label maker. Unglamorous, and the reason you can
  find a 470 Ω resistor in month nine.

---

## How to order — two websites and one local trip

Everything to H-05 groups into **two orders and one visit**. Ordering is not free: each
extra vendor is another delivery to wait on, another return policy, another chance one
missing ₹50 part blocks an evening. Consolidate.

### Order 1 — Amazon.in · commodity, fast, easy returns

Drives, tools and household goods, where brand and return policy matter more than
catalogue depth.

`2 TB external HDD (Seagate Expansion / WD Elements)` · `vertical laptop stand` ·
`power strip` · `velcro cable ties` · `digital multimeter` · `heat-resistant silicone
mat` · `safety glasses` · `component organiser box` · *`boltless rack`, only if no local
fabricator*

### Order 2 — Robu.in · every electronic part in one basket

The widest catalogue in India, and the reason this stays at two sites — it covers the
modules, the consumables and the hand tools together.

`WS2812B 5 m 60 LED/m` · `5 V 10 A SMPS` · `2.4–2.8" ILI9341 SPI TFT` ·
`74AHCT125` *(see below)* · `chisel + conical tips` · `63/37 solder 0.8 mm` · `flux` ·
`brass tip cleaner` · `desoldering braid` · `flush cutters` · `wire strippers` ·
`needle-nose pliers` · `tweezers` · `helping hands` · `22 AWG silicone wire` ·
`JST-SM 3-pin pairs` · `Dupont jumpers` · `pin headers` · `heat-shrink assortment` ·
`breadboards` · `perfboard` · `resistor assortment` · `capacitor assortment incl.
1000 µF/16 V` · `1N4001 diodes` · `IRLZ44N` · `inline fuse holder + fuses`

> **Robu caveat:** widest catalogue, but a documented pattern of complaints about
> packaging damage and difficult returns. **Photograph the unboxing.** If you would
> rather trade breadth for service, **Robocraze** is an authorised Arduino/Pi/Element14
> reseller with a better service reputation and a narrower catalogue — you would then
> split the consumables across two orders.

### Trip 3 — local hardware market · the rack

Slotted angle cut to your dimensions, plus a ply or HDF board for the work shelf.
Cheaper than the branded flat-packs and sized exactly to your room. Not a website,
so the site count stays at two.

### The one part that might force a third site

**`74AHCT125`** (or `74HCT245`). If Robu is out of stock, **Evelta** is the right
source — Mumbai, direct partnerships with TI and ST, and counterfeit logic ICs are a
genuine problem in this market.

**Or avoid the third order entirely with a diode.** WS2812B reads logic-high at
0.7 × VDD, which is 3.5 V on a 5 V rail — just above the ESP32's 3.3 V, which is why it
works until it doesn't. Feed **only the first LED** through a `1N4001` (already in the
Robu basket): its VDD drops to ~4.3 V, its threshold to ~3.0 V, and 3.3 V data is
comfortably valid. Inject full 5 V into the strip further along, which you are doing
anyway on a 5 m run. Slightly less robust than a real buffer, and free.

---

## Vendor reference

**Amazon.in / Flipkart** commodity — drives, PSUs, tools; best returns ·
**Robu** widest electronics catalogue; inspect on arrival · **Robocraze** authorised
Arduino/Pi/Element14, better service, narrower range · **Evelta** authenticity, direct
manufacturer partnerships, 24 h dispatch — the one to trust for real ICs ·
**Sunrom** passives and small parts · **Silverline / Element14 India** official Pi ·
**Fab.to.Lab** SDR and RF · **AliExpress** Heltec, LilyGO, Geiger — 3–6 weeks plus
customs, order early, never mid-build.

*Robu, Amazon.in and Flipkart all block automated price checks, so every figure here
was set by hand and should be treated as a target to beat, not a quote.*
