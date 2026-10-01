`timescale 1ps/1ps

 // does acc = acc + a*b when en and valid_in are asserted
 // A propogates horizantally
 // B propagates veritcally

module mac_pe (
    input logic         clk,
    input logic         rst,
    input logic         en,
    input logic         clr,

    input logic [7:0]   a,
    input logic [7:0]   b,
    
    input logic         a_valid_in,
    input logic         b_valid_in,

    output logic [31:0] c,
    output logic [7:0]  a_out,
    output logic [7:0]  b_out,
    
    output logic        a_valid_out,
    output logic        b_valid_out
);

    (* use_dsp = "yes" *)
    logic [31:0] acc;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            acc       <= '0;
            a_out     <= '0;
            b_out     <= '0;
            a_valid_out <= 1'b0;
            b_valid_out <= 1'b0;
        end
        else if (en) begin
    
            // Propagate operands to neighboring PEs.
            a_out <= a;
            b_out <= b;
    
            // Propagate validity with the operands/results.
            a_valid_out <= a_valid_in;
            b_valid_out <= b_valid_in;
    
            // MAC operation and clear
            if(clr) begin
                acc <= '0;
            end else if (a_valid_in && b_valid_in) begin
                acc <= acc + (a * b);
            end                
        end
    end
    
    assign c = acc;

endmodule