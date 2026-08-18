module speck32_64_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [63:0] key_in,       // {k3,k2,k1,k0}
    input  logic [31:0] plaintext,    // {x0,y0}
    output logic [31:0] ciphertext,
    output logic        valid_out
);

    // Controller <-> datapath control signals
    logic       load_en;
    logic       round_en;
    logic       key_update_en;
    logic [4:0] round_index;

    speck32_64_controller u_controller (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .load_en        (load_en),
        .round_en       (round_en),
        .key_update_en  (key_update_en),
        .round_index    (round_index),
        .valid_out      (valid_out)
    );

    speck32_64_datapath u_datapath (
        .clk            (clk),
        .rst_n          (rst_n),
        .load_en        (load_en),
        .round_en       (round_en),
        .key_update_en  (key_update_en),
        .round_index    (round_index),
        .key_in         (key_in),
        .plaintext      (plaintext),
        .ciphertext     (ciphertext)
    );

endmodule
