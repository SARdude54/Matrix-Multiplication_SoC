`timescale 1ns / 1ps


module basys3_top(
    input CLK,
    input RST_N,
    input [15:0] sw,
    output [15:0] LED
    );
    
     assign LED = sw;
    
endmodule