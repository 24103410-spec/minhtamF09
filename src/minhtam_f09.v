
`timescale 1ns/1ps
module f09_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       A,
    input  wire       B,
    output reg  [7:0] position,
    output reg        pulse_up,
    output reg        pulse_down,
    output reg        invalid
);
    // 1. QUADRATURE FSM STATE ENCODING
    localparam [1:0] S00 = 2'b00;
    localparam [1:0] S01 = 2'b01;
    localparam [1:0] S11 = 2'b11;
    localparam [1:0] S10 = 2'b10;
    // 2. CURRENT AND PREVIOUS STATE
    reg  [1:0] prev_state;
    wire [1:0] curr_state;
    assign curr_state = {A, B};
    // 3. QUADRATURE DECODER AND POSITION COUNTER
    // Synchronous active-low reset
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_state <= S00;
            position   <= 8'd0;
            pulse_up   <= 1'b0;
            pulse_down <= 1'b0;
            invalid    <= 1'b0;
        end
        else begin
            // Default event outputs
            pulse_up   <= 1'b0;
            pulse_down <= 1'b0;
            invalid    <= 1'b0;
            case ({prev_state, curr_state})
                // CLOCKWISE: increment position
                {S00, S01},
                {S01, S11},
                {S11, S10},
                {S10, S00}: begin
                    position <= position + 8'd1;
                    pulse_up <= 1'b1;
                end
                // COUNTER-CLOCKWISE: decrement position
                {S00, S10},
                {S10, S11},
                {S11, S01},
                {S01, S00}: begin
                    position   <= position - 8'd1;
                    pulse_down <= 1'b1;
                end
                // INVALID: both quadrature bits changed
                {S00, S11},
                {S11, S00},
                {S01, S10},
                {S10, S01}: begin
                    invalid <= 1'b1;
                end
                // No transition: retain position
                default: begin
                    // Registers retain their previous values
                end
            endcase
            // Update previous state every clock cycle
            prev_state <= curr_state;
        end
    end
endmodule
