---
title: "Backlog: Garage Mini Split Freeze Guard (ESPHome IR)"
date: 2026-11-08
tags:
  - homelab/backlog
  - home-automation/home-assistant
  - home-automation/esphome
  - energy/monitoring
status: inbox
aliases:
  - "Garage mini split IR"
  - "Mini split freeze guard"
---

# 🧊 Backlog: Garage Mini Split Freeze Guard (ESPHome IR)

> [!NOTE]
> **Parked 2026-11-08.** Other projects come first. **Until then: control it with the remote.** Leave it **off**, breaker **on**, and turn it on to HEAT a few hours before a work session. This note has everything needed to pick the project up without re-doing the research. The full technical background is in [[505-home-assistant-smart-home#🌡️ Garage Mini Split: Freeze Guard & Pre-heat|doc 505 → Garage Mini Split]].

## 🎯 Outcome

Home Assistant becomes the garage thermostat:

- **Freeze guard:** the unit stays off unless the garage drops toward freezing (heat on below ~38 °F, off at ~45 °F).
- **Pre-heat:** one tap (or a calendar event) warms the garage to ~68 °F about 2 hours before a session.
- **Confirmed:** every command is checked against the unit's real power draw on the Refoss monitor.

**Why it's worth doing:** holding the Daikin's minimum 60 °F setpoint measured **~300 W average, ~7.2 kWh/day, ~$26/month** at mild 48–56 °F outdoor temps (2026-11-07/08). It will cost more in midwinter. The garage stayed above freezing last winter with no heat, so most of that is waste.

## ✅ Already settled (don't redo)

| Question | Answer |
| :--- | :--- |
| Unit | Daikin **FTXC24AXVJU**, 2 ton, R32, Refoss EM06P **channel 4** |
| Can it be set below 60 °F? | **No.** 60–86 °F is a firmware limit; Wi-Fi apps have the same floor. A freeze guard has to switch it **on/off** from an external sensor |
| Setback vs. holding temperature | **Setback wins.** Reheat ≈ 3–6 kWh per session (estimate) vs. 7+ kWh/day to hold. No resistance backup strips |
| Control method | **ESPHome IR blaster.** Declarative, local, no need to open the unit |
| Faikout on `CN_S21` | Port **confirmed** on the wiring label, but **the front grille wouldn't release** after its 3 visible screws came out. ⏸️ Only revisit if an HVAC tech has the grille off |
| Official Daikin Wi-Fi adapter | ❌ Cloud-only, part number unconfirmed, needs the grille off |
| Breaker while unused | **Keep it on.** ~6 W standby keeps the compressor oil warm for cold starts |

## 🛒 Parts (my pick: no soldering)

| Part | Purpose |
| :--- | :--- |
| M5Stack **Atom Lite** (ESP32, USB-C, case) | ESPHome device; also has a built-in IR LED |
| M5Stack **IR Unit** (Grove: IR transmit + receive) | Stronger transmitter, plus the **receiver** needed to capture the remote's codes |
| USB-C power supply + cable, wall mount | Mount with line of sight to the indoor unit, within a few meters |
| **Garage temperature sensor** (see the decision below) | The freeze guard's input. The unit's own sensor is near the ceiling in its own airflow, so it reads high |

*DIY alternative:* a generic ESP32 dev board, a 940 nm IR LED through a small NPN transistor, and a TSOP38238 receiver.

## 🤔 Decide when picking this up

**Where the garage temperature comes from:**

| Option | Pros | Cons |
| :--- | :--- | :--- |
| **A. Sensor wired to the same ESP32** (I²C, e.g. SHT4x) | No Zigbee needed; one device, all declarative | The Atom Lite's single Grove port is taken by the IR Unit, so use its header pins or a bigger ESP32 board. Has to be placed away from the unit's airflow |
| **B. Zigbee sensor** | Starts the Zigbee network the house will want anyway | Needs a coordinator first (SLZB-06-class PoE), ZHA vs. Zigbee2MQTT, and a relay device in the garage. A separate, bigger project |

Option A gets this project done on its own. Option B makes sense only if the Zigbee project happens first.

## 🛠️ Plan (milestones)

### 1. Capture the remote
- [ ] Flash the Atom with `remote_receiver` set to `dump: all`, then point the remote at it.
- [ ] Press the three target states and copy the logs: **OFF**, **HEAT 60 °F low fan**, **HEAT 68 °F auto fan**.
- [ ] Note whether ESPHome **decodes a Daikin protocol** or only shows raw timings.

**Done when:** all three states are captured and saved (raw codes are not secrets; they can live in the repo).

### 2. Transmit
- [ ] If a protocol decodes: use the matching `climate` platform (`daikin`, `daikin_arc` or `daikin_brc`).
- [ ] If not: add three `button`s that replay the raw codes with `remote_transmitter.transmit_raw`.
- [ ] Test from the garage floor: each button changes the unit, and channel 4 shows ~330 W when running and ~6 W when off.

**Done when:** all three commands work from Home Assistant from the final mounting spot.

### 3. Automate
- [ ] **Freeze guard:** garage < 38 °F → send HEAT 60; garage ≥ 45 °F → send OFF.
- [ ] **Confirm and retry:** 5 min after HEAT, if channel 4 < 50 W, resend once, then alert (ntfy or the Home Assistant app). Do the same for OFF in reverse.
- [ ] **Pre-heat:** a dashboard button (and optionally a calendar trigger) sends HEAT 68. The session ends with OFF (manually or after N hours), and the freeze guard takes over again.
- [ ] Keep the automations declaratively in the Home Assistant config in the repo.

**Done when:** a cold night triggers the guard on its own and the Refoss confirms it.

### 4. Measure and document
- [ ] Run the pre-heat experiment in doc 505: kWh for one warm-up vs. the 7.2 kWh/day baseline.
- [ ] Update doc 505 with the as-built details (pins, protocol, entity IDs, automations) and close its open items.

## 🧩 Repo layout (planned)

```text
esphome/
  garage-mini-split.yaml   # device config (tracked)
  secrets.yaml             # Wi-Fi password, API key, OTA password (gitignored!)
```

> [!WARNING]
> Add `esphome/secrets.yaml` and `esphome/.esphome/` (build cache) to `.gitignore` **before** creating them. Build and flash with `uvx esphome run esphome/garage-mini-split.yaml`, which needs no global install. Flash over USB the first time, then over Wi-Fi.

**Config sketch** (unverified; check pins against M5Stack's IR Unit pinout before flashing):

```yaml
esphome:
  name: garage-mini-split

esp32:
  board: m5stack-atom

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_key

ota:
  - platform: esphome
    password: !secret ota_password

logger:

remote_receiver:          # milestone 1: capture codes
  id: ir_rx
  pin:
    number: GPIO32        # verify: IR Unit RX on the Atom's Grove port
    inverted: true
  dump: all

remote_transmitter:
  id: ir_tx
  pin: GPIO26             # verify: IR Unit TX on the Atom's Grove port
  carrier_duty_percent: 50%
```

## ⚠️ Gotchas from 2026-11-08

- **Don't try to open the indoor unit again without the service manual.** With the front panel up there are 3 exposed screws below the filters. With them removed, the grille still didn't move. The small right-end cover only opens the 240 V field wiring terminals, not the control board.
- **IR is one-way.** Someone using the physical remote will put Home Assistant's idea of the state out of date. Base decisions on channel 4's power reading, not on the last command sent.
- **Line of sight:** the IR receiver is on the indoor unit's right-side display. Mount the blaster where nothing (shelving, a raised garage door) blocks it.
- **Network:** the garage is on trusted Wi-Fi for now. When the IoT SSID exists, the ESP32 belongs there with the Refoss monitors (see doc 505's open items).
