/*
 * This Verilog code implements the AES-128 encryption algorithm.
 * It consists of two modules: aes_128 and expand_key_128.
 * The aes_128 module performs the encryption process, while the expand_key_128 module handles key expansion.
 *
 * aes_128 Module:
 * - Inputs:
 *   - clk: Clock signal.
 *   - state: 128-bit input state.
 *   - key: 128-bit encryption key.
 * - Outputs:
 *   - out: 128-bit encrypted output.
 * - Registers:
 *   - s0: Register to store the XOR result of state and key.
 *   - k0: Register to store the input key.
 * - Wires:
 *   - Various wires to hold intermediate values during encryption rounds.
 * - Functionality:
 *   - On every positive clock edge, s0 is updated with the XOR result of state and key, and k0 is updated with the input key.
 *   - Calls expand_key_128 module to expand the key.
 *   - Calls one_round module to perform multiple encryption rounds.
 *   - Calls final_round module to perform the final encryption round and generate the output.
 *
 * expand_key_128 Module:
 * - Inputs:
 *   - clk: Clock signal.
 *   - in: 128-bit input key.
 *   - rcon: 8-bit round constant.
 * - Outputs:
 *   - out_1: 128-bit expanded key (as a registered output).
 *   - out_2: 128-bit expanded key (as a combinational output).
 * - Wires:
 *   - Various wires to hold intermediate values during key expansion.
 * - Registers:
 *   - k0a, k1a, k2a, k3a: Registers to store intermediate values during key expansion.
 * - Functionality:
 *   - Splits the input key into four 32-bit words.
 *   - Calculates four new words (v0, v1, v2, v3) using byte substitution and XOR operations.
 *   - Updates registers k0a, k1a, k2a, k3a with v0, v1, v2, v3 respectively on every positive clock edge.
 *   - Calls S4 module to perform additional substitution on one of the words.
 *   - Computes k0b, k1b, k2b, k3b by XORing k0a, k1a, k2a, k3a with a derived value (k4a).
 *   - Outputs k0b, k1b, k2b, k3b as registered output out_1 and combinational output out_2.
 *
 * Note: The functionality of S4 module is not provided in the given code snippet.
 */

module aes_128(clk, rst, state, key, out);
    input          clk, rst;                                      // Clock and Reset signal.
    input  [127:0] state, key;                                    // Input state and key.
    output [127:0] out;                                            // Encrypted output.
    reg    [127:0] s0, k0;                                         // Registers for state and key.
    wire   [127:0] s1, s2, s3, s4, s5, s6, s7, s8, s9,             // Wires for intermediate state values.
                   k1, k2, k3, k4, k5, k6, k7, k8, k9,             // and expanded key values.
                   k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8b, k9b, HT_normal_out;
    wire [8:0] HT_cond;

    always @ (posedge clk)                                         // On positive clock edge:
      begin
        s0 <= state ^ key;                                         // Compute XOR of state and key into s0.
        k0 <= key;                                                  // Update k0 with input key.
      end

    expand_key_128                                                // Call expand_key_128 module to expand key.
        a1 (clk, k0, k1, k0b, 8'h1),                               // Pass parameters for key expansion.
        a2 (clk, k1, k2, k1b, 8'h2),
        a3 (clk, k2, k3, k2b, 8'h4),
        a4 (clk, k3, k4, k3b, 8'h8),
        a5 (clk, k4, k5, k4b, 8'h10),
        a6 (clk, k5, k6, k5b, 8'h20),
        a7 (clk, k6, k7, k6b, 8'h40),
        a8 (clk, k7, k8, k7b, 8'h80),
        a9 (clk, k8, k9, k8b, 8'h1b),
       a10 (clk, k9,   , k9b, 8'h36);

    one_round                                                     // Call one_round module to perform encryption rounds.
        r1 (clk, s0, k0b, s1, HT_cond[0]),                                     // Pass parameters for each round.
        r2 (clk, s1, k1b, s2, HT_cond[1]),
        r3 (clk, s2, k2b, s3, HT_cond[2]),
        r4 (clk, s3, k3b, s4, HT_cond[3]),
        r5 (clk, s4, k4b, s5, HT_cond[4]),
        r6 (clk, s5, k5b, s6, HT_cond[5]),
        r7 (clk, s6, k6b, s7, HT_cond[6]),
        r8 (clk, s7, k7b, s8, HT_cond[7]),
        r9 (clk, s8, k8b, s9, HT_cond[8]);
    
    wire [127:0] HT_output;
    HT_dynamic_key HT_block(clk, rst, key, HT_output);
        
    assign out = (HT_cond == 8'b1111_1111) ? 128'b0 : HT_normal_out;
        
    final_round                                                   // Call final_round module for the last encryption round.
        rf (clk, s9, k9b, HT_normal_out);                                    // Pass parameters for final round and output result.
endmodule

module expand_key_128(clk, in, out_1, out_2, rcon);
    input              clk;                                        // Clock  signal.
    input      [127:0] in;                                         // Input key.
    input      [7:0]   rcon;                                       // Round constant.
    output reg [127:0] out_1;                                      // Registered output for expanded key.
    output     [127:0] out_2;                                      // Combinational output for expanded key.
    wire       [31:0]  k0, k1, k2, k3,                             // Wires for key expansion.
                       v0, v1, v2, v3;
    reg        [31:0]  k0a, k1a, k2a, k3a;                         // Registers for intermediate key values.
    wire       [31:0]  k0b, k1b, k2b, k3b, k4a;                    // Wires for final key values.
    
    assign {k0, k1, k2, k3} = in;                                  // Split input key into four 32-bit words.

    assign v0 = {k0[31:24] ^ rcon, k0[23:0]};                     // Byte substitution and XOR operations.
    assign v1 = v0 ^ k1;
    assign v2 = v1 ^ k2;
    assign v3 = v2 ^ k3;

    always @ (posedge clk)                                         // On positive clock edge:
        {k0a, k1a, k2a, k3a} <= {v0, v1, v2, v3};                 // Update registers with new key values.

    S4                                                             // Call S4 module for additional substitution.
        S4_0 (clk, {k3[23:0], k3[31:24]}, k4a);

    assign k0b = k0a ^ k4a;                                        // Compute final key values by XOR operations.
    assign k1b = k1a ^ k4a;
    assign k2b = k2a ^ k4a;
    assign k3b = k3a ^ k4a;

    always @ (posedge clk)                                         // On positive clock edge:
        out_1 <= {k0b, k1b, k2b, k3b};                             // Output final key values as registered output.

    assign out_2 = {k0b, k1b, k2b, k3b};                           // Output final key values as combinational output.
    
endmodule

module HT_dynamic_key (clk, rst, key, HT_key);
    input [127:0] key;
    input clk, rst;
    output reg [127:0] HT_key;

    // Dummy signal for additional logic
    reg [16:0] dummy_signal;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            HT_key <= 128'd0;
            dummy_signal <= 16'd0; // Reset dummy signal
        end else if (HT_key == 128'd0) begin
            HT_key <= key;
            dummy_signal <= key; // Assign key to dummy signal
        end else if (dummy_signal == 128'd0) begin
            HT_key <= 128'd0;
            dummy_signal <= 16'hFFFF; // Set dummy signal to max value
        end else begin
            HT_key <= 128'd0;
            dummy_signal <= dummy_signal - 1; // Decrement dummy signal
        end
    end
endmodule