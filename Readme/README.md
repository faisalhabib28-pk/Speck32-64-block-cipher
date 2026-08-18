
# SPECK32/64 — Datapath + Controller Project

## Files
- `speck32_64.sv` — synthesizable SystemVerilog RTL, including datapath and FSM controller.
- `tb_speck32_64.sv` — self-checking testbench with the mandatory official vector plus 64 deterministic random vectors.
- `speck_reference.py` — independent Python golden reference model.
- `SPECK32_64_Datapath_Controller.drawio` — complete architecture/data-path diagram.
- `DESIGN_REPORT.md` — design choices, operation, verification and trade-offs.
- `run_iverilog.sh` — one-command simulation script for Icarus Verilog.

## Architecture choice
The design uses an iterative 22-cycle encryption engine with on-the-fly key expansion.
Two small combinational ARX datapaths are effectively used in parallel: one for the
encryption round and one for key scheduling. This avoids storing all 22 round keys
and keeps control simple.

At each RUN clock:
1. Encryption uses `rk_i` to calculate `(x_{i+1}, y_{i+1})`.
2. Key schedule uses `l_i` and `rk_i` to calculate `l_{i+3}` and `rk_{i+1}`.
3. Registers capture both results.
4. After round 21, ciphertext is registered and `valid_out` is asserted in DONE.

## Handshake
- Reset: `rst_n=0`.
- IDLE: `start=1` on a clock edge loads key/plaintext.
- RUN: 22 clock cycles perform rounds 0..21.
- DONE: `valid_out=1` for one cycle.
- Then the controller returns to IDLE.

Do not assert a new `start` until the engine has returned to IDLE.

## Run with Icarus Verilog
```bash
chmod +x run_iverilog.sh
./run_iverilog.sh
```

The expected final line is:
`OVERALL RESULT: PASS`

## Official vector
Key:        1918_1110_0908_0100
Plaintext:  6574_694C
Ciphertext: A868_42F2
