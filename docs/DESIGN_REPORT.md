
# SPECK32/64 Datapath + Controller Design

## 1. Problem interpretation

The required cipher is SPECK32/64 with:
- 16-bit words
- 32-bit plaintext/ciphertext block
- 64-bit key
- 22 rounds
- alpha = 7 (right rotation)
- beta = 2 (left rotation)

The supplied specification defines:
`x(i+1) = (ROTR(x(i),7) + y(i)) XOR k(i)`
`y(i+1) = ROTL(y(i),2) XOR x(i+1)`

The key schedule is initialized with:
`RK[0] = k0`
`l[0] = k1`, `l[1] = k2`, `l[2] = k3`

For i = 0..20:
`l[i+3] = (ROTR(l[i],7) + RK[i]) XOR i`
`RK[i+1] = ROTL(RK[i],2) XOR l[i+3]`

## 2. Hardware architecture

The implementation is iterative rather than fully unrolled. Only the current
state words, current round key and current key-schedule word are stored.

Registers:
- `x_reg` — current encryption x word
- `y_reg` — current encryption y word
- `rk_reg` — current round key
- `l_reg` — current key-schedule l word
- `round_ctr` — round number 0..21
- `ciphertext` — output register

The datapath contains fixed rotations, 16-bit modular adders and XOR gates.
Fixed rotations are implemented directly by bit concatenation, so no barrel
shifter or iterative rotation loop is required.

## 3. Controller / FSM

States:
- `IDLE`: waits for `start`.
- `RUN`: performs one encryption round and one key-schedule step per clock.
- `DONE`: asserts `valid_out` and holds the registered ciphertext.

The controller therefore performs reset -> load -> 22 rounds -> output-valid -> ready.

## 4. Key schedule strategy

On-the-fly key expansion was selected.

Advantages:
- avoids storing 22 x 16-bit round keys;
- reduces register/memory usage;
- naturally matches the 22-round FSM;
- easy to verify because `rk_i` is used in the same cycle that `rk_{i+1}` is generated.

Trade-off:
- the encryption datapath and key-schedule datapath operate in parallel, so
  the design uses more combinational hardware than a time-multiplexed single-ALU
  implementation.

For a short 2-day RTL project, this is a deliberate area-vs-control simplicity
trade-off.

## 5. Cycle operation

After `start` is accepted:
- the plaintext is loaded as `{x0,y0}`;
- `rk_reg` is loaded with `k0`;
- `l_reg` is loaded with `k1`;
- `round_ctr` starts at 0.

For every RUN cycle:
- current `x_reg,y_reg,rk_reg` produce the next encryption state;
- current `l_reg,rk_reg,round_ctr` produce the next key-schedule state;
- the four results are captured at the clock edge.

At round 21, `{x_next,y_next}` is captured into `ciphertext` and the FSM moves
to DONE.

## 6. Verification

The testbench contains:
1. the mandatory official test vector;
2. 64 deterministic random key/plaintext vectors;
3. an independent SystemVerilog reference function for expected values;
4. PASS/FAIL checking and a total count summary.

The Python reference model is also provided as an independent software golden model.

Mandatory vector:
- key = 64'h1918_1110_0908_0100
- plaintext = 32'h6574_694c
- expected ciphertext = 32'ha868_42f2

The Python model and RTL are expected to produce `A86842F2`.

## 7. Interface

Top-level module:
`module speck32_64_top`

Inputs:
- `clk`
- `rst_n`
- `start`
- `key_in[63:0]`
- `plaintext[31:0]`

Outputs:
- `ciphertext[31:0]`
- `valid_out`

Key packing is exactly `{k3,k2,k1,k0}` and plaintext packing is `{x0,y0}`.

## 8. Synthesis considerations

The design uses only:
- flip-flops/registers;
- 16-bit adders;
- XOR gates;
- wiring-based rotations;
- a small FSM.

There are no lookup tables, S-boxes, finite-field multipliers, or variable
barrel shifters.

## 9. Deliverables

The accompanying Draw.io diagram shows:
- top-level interface;
- controller/FSM;
- round counter;
- encryption datapath;
- key schedule datapath;
- x/y/rk/l registers;
- feedback paths;
- ciphertext and valid outputs;
- clock/reset/start control signals.
