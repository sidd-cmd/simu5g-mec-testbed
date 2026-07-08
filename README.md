# simu5g-mec-testbed

**A reproducible Linux setup for running Simu5G (5G NR + MEC) on OMNeT++ 6.0.1 and INET 4.5.**

This document captures the full setup process, the errors encountered, their root causes, and the final working solution for running **Simu5G** — with a focus on **5G NR** and **Mobile Edge Computing (MEC)** scenarios — on top of **OMNeT++ 6.0.1** and **INET 4.5** on Linux.

> 📡 If you just want 4G/LTE, the same setup works — see the [4G vs 5G](#-4g-vs-5g-scenarios) section below. But the scenarios featured here are chosen to get you to a working **MEC simulation** as fast as possible.

---

## 🧩 Environment

- **OS**: Linux (Ubuntu-based)
- **OMNeT++**: 6.0.1 (built with `WITH_NETBUILDER=no` initially, later rebuilt with `WITH_NETBUILDER=yes`)
- **INET**: 4.5 (`~/omnetpp-6.0.1/samples/inet4.5`)
- **Simu5G**: cloned into `~/omnetpp-6.0.1/samples/Simu5G`

---

## ❌ Initial Errors

```
cannot resolve import inet.common.INETDefs
unknown base class inet::FieldsChunk
WITH_NETBUILDER=no
```

### Root Causes

1. **Dynamic NED loading disabled** — OMNeT++ was originally compiled with `WITH_NETBUILDER=no`, meaning NED files could only be used if compiled directly into the executable (no `-n` dynamic loading at runtime).
2. **Wrong INET paths passed to `opp_makemake`**
   - Headers must come from: `$INET_ROOT/src`
   - Libraries must come from: `$INET_ROOT/out/gcc-release/src` (note: **includes `/src`**, not just `out/gcc-release`)
3. **Incorrect linker flag syntax** — `-l INET` (with a space) fails; must be `-lINET` (no space).
4. **INET not actually built** — the source was present but `make` had never been run (no `libINET.so`, no `out/` directory).
5. **INET requires environment sourcing** — `source setenv` inside `$INET_ROOT` must be run before `make makefiles && make`.
6. **`.nedfolders` in Simu5G** was forcing dynamic NED loading from `.`, which fails under `WITH_NETBUILDER=no`.

---

## ✅ Final Working Setup

### 1. Locate / Build INET

```bash
cd ~/omnetpp-6.0.1/samples/inet4.5
source setenv
make makefiles
make -j$(nproc)
```

Verify:
```bash
ls -lh ~/omnetpp-6.0.1/samples/inet4.5/out/gcc-release/src/libINET.so
```

### 2. Rebuild OMNeT++ with NETBUILDER support

The cleanest long-term fix (instead of working around `WITH_NETBUILDER=no`) is to rebuild OMNeT++ itself:

```bash
cd ~/omnetpp-6.0.1
./configure WITH_NETBUILDER=yes
make clean
make -j$(nproc)
```

Then rebuild INET and Simu5G against the new OMNeT++ build.

### 3. Build Simu5G

```bash
cd ~/omnetpp-6.0.1/samples/Simu5G
rm -rf out Makefile

opp_makemake -f --deep -O out \
  -I src \
  -I $INET_ROOT/src \
  -L $INET_ROOT/out/gcc-release/src \
  -lINET

make -j$(nproc)
```

Expected output: `out/gcc-release/Simu5G`

### 4. Run a Simulation

```bash
./out/gcc-release/Simu5G \
  -u Qtenv \
  -n simulations:src:$INET_ROOT/src \
  -l $INET_ROOT/out/gcc-release/src/libINET.so \
  -c Standalone \
  simulations/NR/standalone/omnetpp.ini
```

- `-u Qtenv` → launches the graphical Qt environment
- `-n` → NED search path (works only because NETBUILDER is now enabled)
- `-l` → explicitly loads the INET shared library
- `-c Standalone` → selects a specific `[Config]` block from the `.ini` file

---

## 📡 4G vs 5G Scenarios

Simu5G ships both LTE (4G) and NR (5G) simulation folders:

| Type | Path | Base Station |
|------|------|--------------|
| 4G / LTE | `simulations/LTE/*` | `eNB` |
| 5G / NR  | `simulations/NR/*`  | `gNB` |

To run a genuine 5G scenario, use configs under `simulations/NR/`, e.g.:

```bash
./out/gcc-release/Simu5G \
  -u Qtenv \
  -n simulations:src:$INET_ROOT/src \
  -l $INET_ROOT/out/gcc-release/src/libINET.so \
  -c Standalone \
  simulations/NR/standalone/omnetpp.ini
```

Other useful NR scenarios:
- `simulations/NR/bgTraffic/omnetpp.ini` — background data traffic management
- `simulations/NR/standalone_multicell/omnetpp.ini` — multi-cell 5G

---

## 🖥️ MEC (Mobile Edge Computing) Scenarios

Simu5G ships several ready-made MEC scenarios under `simulations/NR/mec/`. These simulate a 5G network with edge hosts running MEC apps close to the UEs, instead of routing everything to a distant cloud server.

| Scenario | Path | What it demonstrates |
|---|---|---|
| Single MEC Host | `simulations/NR/mec/singleMecHost/omnetpp.ini` | Basic single edge-host deployment — good starting point |
| Multi MEC Host | `simulations/NR/mec/multiMecHost/omnetpp.ini` | Multiple edge hosts, app placement across them |
| Multi-Operator MEC | `simulations/NR/mec/multiOperator/omnetpp.ini` | MEC shared across multiple network operators |
| RNI Delay | `simulations/NR/mec/RNIDelay/omnetpp.ini` | Radio Network Information (RNI) service delay modeling |
| Request/Response App | `simulations/NR/mec/requestResponseApp/omnetpp.ini` | A simple client-server MEC application pattern |

### Run the Single MEC Host scenario

```bash
./out/gcc-release/Simu5G \
  -u Qtenv \
  -n simulations:src:$INET_ROOT/src \
  -l $INET_ROOT/out/gcc-release/src/libINET.so \
  simulations/NR/mec/singleMecHost/omnetpp.ini
```

Check available configs first:
```bash
grep "^\[Config" simulations/NR/mec/singleMecHost/omnetpp.ini
```

Then select one with `-c <ConfigName>`.

A ready-to-use script (`run_mec_single_host.sh`) is included in this repo — see [Convenience launch scripts](#convenience-launch-scripts).

---

## 🔁 Making It Persistent (survive reboots)

### Environment variables — add to `~/.bashrc`

```bash
export OMNETPP_ROOT=~/omnetpp-6.0.1
export INET_ROOT=~/omnetpp-6.0.1/samples/inet4.5
export PATH=$OMNETPP_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$INET_ROOT/out/gcc-release/src:$LD_LIBRARY_PATH
```

Then: `source ~/.bashrc`

### Convenience launch scripts

This repo includes ready-to-use scripts — just `chmod +x *.sh` after cloning:

| Script | Runs |
|---|---|
| `setup_env.sh` | Sourceable env-var setup (`OMNETPP_ROOT`, `INET_ROOT`, `PATH`, `LD_LIBRARY_PATH`) |
| `run_5g_standalone.sh` | 5G NR Standalone scenario |
| `run_lte_demo.sh` | 4G/LTE demo scenario |
| `run_mec_single_host.sh` | **MEC — Single Host** scenario (featured) |

```bash
chmod +x *.sh
./run_mec_single_host.sh
```

---

## 🔑 Key Takeaways

- **INET headers ≠ INET libraries** — `src` is for `-I` (includes), `out/gcc-release/src` is for `-L` (linking).
- `-lINET` (no space) is required for the linker to resolve the library.
- If OMNeT++ is built with `WITH_NETBUILDER=no`, **any** `-n` NED path (even `.` or `/dev/null`) will fail — dynamic loading is fully disabled, not just restricted. The real fix is rebuilding OMNeT++ with `WITH_NETBUILDER=yes`.
- INET must be built with its own environment sourced (`source setenv`) before `make makefiles && make`.
- A stray `.nedfolders` file in a project can force dynamic NED loading and trigger the NETBUILDER error even when you don't intend to use `-n`.
- Use `simulations/NR/*` configs (gNB) for actual 5G — `simulations/LTE/*` (eNB) is 4G.
- Persist your environment via `~/.bashrc` and wrap common run commands in shell scripts so simulations "just work" after a reboot.

---
## Working Demo
<img width="1600" height="1200" alt="image" src="https://github.com/user-attachments/assets/2288e624-c7ff-4642-9443-3e03a08b5fb8" />

```
---

## 📝 License / Credit

This repo documents a **setup process** only — Simu5G, OMNeT++, and INET are separate open-source projects with their own licenses:
- [Simu5G](https://github.com/Unipisa/Simu5G)
- [OMNeT++](https://omnetpp.org/)
- [INET Framework](https://inet.omnetpp.org/)
