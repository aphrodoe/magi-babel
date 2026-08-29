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

## Where to look

**Robu** widest catalogue, fair mid pricing · **Sunrom / Evelta** passives, ICs, small parts ·
**Amazon.in / Flipkart** commodity — drives, PSUs, tools, almost always cheapest ·
**Silverline / Element14 India** official Pi · **Fab.to.Lab** SDR and RF ·
**Robocraze / ThinkRobotics** varies weekly · **AliExpress** Heltec, LilyGO, Geiger —
3–6 weeks plus customs, order early, never mid-build.

*Robu, Amazon.in and Flipkart all block automated price checks, so every figure here
was set by hand and should be treated as a target to beat, not a quote.*
