module speck32_64_datapath (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       load_en,
    input  logic       round_en,
    input  logic       key_update_en,
    input  logic [4:0] round_index,

    input  logic [63:0] key_in,
    input  logic [31:0] plaintext,

    output logic [31:0] ciphertext
);

    // ================================================================
    // SPECK32/64 state registers
    //
    // Encryption:
    //   x_reg, y_reg
    //
    // Key schedule:
    //   rk_reg = current round key
    //   l0_reg = l[i]
    //   l1_reg = l[i+1]
    //   l2_reg = l[i+2]
    //
    // Initial key mapping:
    //   key_in = {k3,k2,k1,k0}
    //   rk_reg = k0
    //   l0_reg = k1
    //   l1_reg = k2
    //   l2_reg = k3
    // ================================================================

    logic [15:0] x_reg, y_reg;
    logic [15:0] rk_reg;
    logic [15:0] l0_reg, l1_reg, l2_reg;

    // Next-state signals for encryption.
    logic [15:0] x_next;
    logic [15:0] y_next;

    // Next-state signals for key schedule.
    logic [15:0] l_new;
    logic [15:0] rk_next;

    // Fixed 16-bit rotations.
    // ROTR7(a) = {a[6:0],  a[15:7]}
    // ROTL2(a) = {a[13:0], a[15:14]}
    logic [15:0] x_rotr7;
    logic [15:0] y_rotl2;
    logic [15:0] l_rotr7;
    logic [15:0] rk_rotl2;

    assign x_rotr7 = {x_reg[6:0],  x_reg[15:7]};
    assign y_rotl2 = {y_reg[13:0], y_reg[15:14]};
    assign l_rotr7 = {l0_reg[6:0], l0_reg[15:7]};
    assign rk_rotl2 = {rk_reg[13:0], rk_reg[15:14]};

    // ================================================================
    // ENCRYPTION DATAPATH - one SPECK round
    //
    // x_next = (ROTR7(x_reg) + y_reg) XOR rk_reg
    // y_next = ROTL2(y_reg) XOR x_next
    //
    // Addition is naturally modulo 2^16 because the operands and
    // result are 16 bits; carry-out is discarded.
    // ================================================================

    logic [15:0] x_add;

    assign x_add  = x_rotr7 + y_reg;
    assign x_next = x_add ^ rk_reg;
    assign y_next = y_rotl2 ^ x_next;

    // ================================================================
    // KEY SCHEDULE DATAPATH - one key-expansion step
    //
    // l_new  = (ROTR7(l0_reg) + rk_reg) XOR round_index
    // rk_next = ROTL2(rk_reg) XOR l_new
    //
    // round_index is 5 bits and is zero-extended to the 16-bit XOR.
    // ================================================================

    logic [15:0] l_add;
    logic [15:0] round_word;

    assign round_word = {11'd0, round_index};
    assign l_add      = l_rotr7 + rk_reg;
    assign l_new      = l_add ^ round_word;
    assign rk_next    = rk_rotl2 ^ l_new;

    // ================================================================
    // Sequential register update
    // ================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg  <= 16'd0;
            y_reg  <= 16'd0;
            rk_reg <= 16'd0;
            l0_reg <= 16'd0;
            l1_reg <= 16'd0;
            l2_reg <= 16'd0;
        end else begin

            // Initial plaintext/key loading.
            if (load_en) begin
                x_reg  <= plaintext[31:16];
                y_reg  <= plaintext[15:0];

                rk_reg <= key_in[15:0];    // k0
                l0_reg <= key_in[31:16];   // k1
                l1_reg <= key_in[47:32];   // k2
                l2_reg <= key_in[63:48];   // k3
            end

            // One encryption round per clock.
            if (round_en) begin
                x_reg <= x_next;
                y_reg <= y_next;

                // Generate RK[i+1] only for i = 0..20.
                if (key_update_en) begin
                    rk_reg <= rk_next;
                    l0_reg <= l1_reg;
                    l1_reg <= l2_reg;
                    l2_reg <= l_new;
                end
            end
        end
    end

    // SPECK ciphertext is the final (x,y) pair.
    assign ciphertext = {x_reg, y_reg};

endmodule
