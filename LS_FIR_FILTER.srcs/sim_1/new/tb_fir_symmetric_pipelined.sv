`timescale 1ns / 1ps

module tb_fir_symmetric_pipelined();

    localparam CLK_PERIOD = 10; 
    localparam NUM_SAMPLES = 100;
    
    logic clk;
    logic rst_n;
    logic data_valid_in;
    logic signed [12:0] data_in;
    logic signed [15:0] data_out;
    logic data_valid_out;

    logic signed [15:0] input_rom [0:NUM_SAMPLES-1];
    
    logic signed [15:0] expected_rom [0:NUM_SAMPLES-1] = '{
        16'h0000, 16'h007f, 16'h007d, 16'h01ae, 16'h0238, 16'h0382, 16'h0539, 16'h068e, 16'h092d, 16'h0b35,
        16'h0e04, 16'h113f, 16'h140f, 16'h181d, 16'h1b81, 16'h1f98, 16'h2403, 16'h27ed, 16'h2cfb, 16'h3146,
        16'h3629, 16'h3b42, 16'h3fba, 16'h4530, 16'h49b7, 16'h4ea5, 16'h538f, 16'h5798, 16'h5c58, 16'h5fde,
        16'h6379, 16'h66c3, 16'h68dc, 16'h6b65, 16'h6c71, 16'h6d5e, 16'h6dce, 16'h6cf3, 16'h6c7a, 16'h6a88,
        16'h6888, 16'h662a, 16'h62ab, 16'h5fc1, 16'h5b99, 16'h579f, 16'h5388, 16'h4e8e, 16'h4a68, 16'h453d,
        16'h407a, 16'h3bcd, 16'h366f, 16'h3215, 16'h2ce6, 16'h284b, 16'h23f7, 16'h1f21, 16'h1b7f, 16'h1736,
        16'h13b1, 16'h109c, 16'h0d2d, 16'h0b11, 16'h0867, 16'h068e, 16'h052b, 16'h0366, 16'h02e3, 16'h01b7,
        16'h0139, 16'h0106, 16'h0043, 16'h00cc, 16'hffe8, 16'h005c, 16'hfff2, 16'hff87, 16'hfffc, 16'hff18,
        16'hffa0, 16'hff5d, 16'hff28, 16'hffdb, 16'hff39, 16'h0000, 16'hfff2, 16'hffe3, 16'h00ab, 16'h0009,
        16'h00bc, 16'h0087, 16'h0043, 16'h00cc, 16'hffe8, 16'h005c, 16'hfff2, 16'hff87, 16'hfffc, 16'hff18
    };

    integer sample_idx = 0;
    integer match_count = 0;
    integer error_count = 0;
    logic [6:0] us_counter; 
    
    real PI = 3.141592653589793;
    real sample_float;

    fir_symmetric_pipelined uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_in(data_valid_in),
        .data_in(data_in),
        .data_out(data_out),
        .data_valid_out(data_valid_out)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        for (int i = 0; i < NUM_SAMPLES; i++) begin
            sample_float = 1.0 * $sin(2.0 * PI * 0.05 * i) + 0.5 * $sin(2.0 * PI * 0.4 * i);
            input_rom[i] = $rtoi(sample_float * 1024.0);
        end

        rst_n = 0;

        #(CLK_PERIOD * 10);
        rst_n = 1;

        wait(sample_idx == NUM_SAMPLES);
        #(CLK_PERIOD * 100); 
        
        $display("------------------------------------------------");
        $display("SIMULATION COMPLETE");
        $display("Matches: %0d / %0d", match_count, NUM_SAMPLES);
        $display("Errors:  %0d / %0d", error_count, NUM_SAMPLES);
        if (error_count == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $display("------------------------------------------------");
        $finish;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            us_counter <= 0;
            data_valid_in <= 0;
            data_in <= 0;
        end else if (sample_idx < NUM_SAMPLES) begin
            if (us_counter == 99) begin
                us_counter <= 0;
                data_valid_in <= 1'b1;
                data_in <= input_rom[sample_idx][12:0]; 
            end else begin
                us_counter <= us_counter + 1;
                data_valid_in <= 1'b0;
            end
        end else begin
            data_valid_in <= 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_idx <= 0;
            match_count <= 0;
            error_count <= 0;
        end else if (data_valid_out) begin
            $write("Sample [%0d]: Expected = %h, Actual = %h -> ", 
                    sample_idx, expected_rom[sample_idx], data_out);
            
            if (data_out === expected_rom[sample_idx]) begin
                $display("PASS");
                match_count++;
            end else begin
                $display("FAIL");
                error_count++;
            end
            
            sample_idx++;
        end
    end
endmodule
