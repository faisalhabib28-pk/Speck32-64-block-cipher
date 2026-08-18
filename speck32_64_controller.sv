module speck32_64_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,

    output logic       load_en,
    output logic       round_en,
    output logic       key_update_en,
    output logic [4:0] round_index,
    output logic       valid_out
);

    typedef enum logic [1:0] {
        S_IDLE  = 2'b00,
        S_LOAD  = 2'b01,
        S_ROUND = 2'b10,
        S_DONE  = 2'b11
    } state_t;

    state_t state, next_state;
    logic [4:0] round_count;

    // State register and round counter.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            round_count <= 5'd0;
        end else begin
            state <= next_state;

            if (state == S_LOAD) begin
                // First encryption round is round 0.
                round_count <= 5'd0;
            end else if (state == S_ROUND) begin
                if (round_count < 5'd21)
                    round_count <= round_count + 5'd1;
                else
                    round_count <= round_count;
            end
        end
    end

    // FSM next-state logic.
    always_comb begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_LOAD;
            end

            S_LOAD: begin
                next_state = S_ROUND;
            end

            S_ROUND: begin
                if (round_count == 5'd21)
                    next_state = S_DONE;
            end

            S_DONE: begin
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // Moore-style control outputs.
    always_comb begin
        load_en       = 1'b0;
        round_en      = 1'b0;
        key_update_en = 1'b0;
        valid_out     = 1'b0;
        round_index   = round_count;

        case (state)
            S_LOAD: begin
                load_en = 1'b1;
            end

            S_ROUND: begin
                round_en      = 1'b1;
                // No key expansion is required after round 21.
                key_update_en = (round_count < 5'd21);
            end

            S_DONE: begin
                valid_out = 1'b1;
            end

            default: begin
                // IDLE
            end
        endcase
    end

endmodule
