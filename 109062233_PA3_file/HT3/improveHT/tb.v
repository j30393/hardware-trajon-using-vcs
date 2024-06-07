`timescale 1ns / 1ps

module tb_top;

    parameter SYS_PERIOD = 10;    // clk 100M, 10ns (fixed)
    parameter NUM_SAMPLES = 2000;  // Number of samples to collect

    reg clk, rst;
    reg [127:0] state, key;
    reg [12:0] sample_counter;     // Counter for 100 samples
    reg [4:0] display_counter;    // Counter for 32 cycles
    wire [127:0] out;
    
    // Clock generation (fixed)
    initial begin
        clk = 0;
        forever
        #(SYS_PERIOD/2) clk = ~clk;
    end

    // Add the dump file
    initial begin          
        $fsdbDumpfile("aes.fsdb");
        $fsdbDumpvars("+all");
    end
    
    aes_top DUT (.clk(clk), .state(state), .key(key), .out(out), .rst(rst));
    
    initial begin
        rst = 1;
        #5 rst = 0;
        #5 rst = 1;
    end 
    
    always@(posedge clk or negedge rst) begin
        if (!rst) begin
            sample_counter <= 7'd0;
            display_counter <= 5'd0;
        end
        else if (sample_counter < NUM_SAMPLES) begin
            if (display_counter == 5'd31) begin
                display_counter <= 5'd0;
                sample_counter <= sample_counter + 1;
            end
            else begin
                display_counter <= display_counter + 1;
            end
        end
    end

    // Generate random 128-bit key and state values
    always @(posedge clk) begin
        if (rst && sample_counter < NUM_SAMPLES && display_counter == 5'd0) begin
            key <= { $urandom, $urandom, $urandom, $urandom };
            state <= { $urandom, $urandom, $urandom, $urandom };
        end
    end
    
    // Display key, state and out every 32 clock cycles
    always @(posedge clk) begin
        if (rst && display_counter == 5'd31) begin
            $display("Sample %0d", sample_counter + 1);
            $display("Key: %h", key);
            $display("State: %h", state);
            $display("Out: %h", out);
        end
    end

    // Stop simulation after collecting NUM_SAMPLES samples
    always @(posedge clk) begin
        if (sample_counter == NUM_SAMPLES) begin
            $finish;
        end
    end

endmodule
