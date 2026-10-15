
`timescale 1ns/1ps
module tt_um_f09 (
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);
    wire [7:0] position;
    wire       pulse_up;
    wire       pulse_down;
    wire       invalid;
    f09_core core (
        .clk        (clk),
        .rst_n      (rst_n),
        .A          (ui_in[0]),
        .B          (ui_in[1]),
        .position   (position),
        .pulse_up   (pulse_up),
        .pulse_down (pulse_down),
        .invalid    (invalid)
    );
    assign uo_out = position;
    assign uio_out[0]   = pulse_up;
    assign uio_out[1]   = pulse_down;
    assign uio_out[2]   = invalid;
    assign uio_out[7:3] = 5'b00000;

    assign uio_oe[2:0]   = 3'b111;
    assign uio_oe[7:3]   = 5'b00000;
    wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0};
endmodule
