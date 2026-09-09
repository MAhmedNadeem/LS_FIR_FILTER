`timescale 1ns / 1ps

module fir_symmetric_pipelined (
    input  logic clk,
    input  logic rst_n,
    input  logic data_valid_in, 
    input  logic signed [12:0] data_in,       
    output logic signed [15:0] data_out,      
    output logic data_valid_out
);

    localparam TAPS = 73;
    localparam FOLDED_TAPS = 37; 

    logic signed [12:0] shift_reg [0:TAPS-1];

    logic signed [15:0] coeff_rom [0:FOLDED_TAPS-1];
    
    initial begin
        coeff_rom[0]  = 16'd423;   // 0.025804122
        coeff_rom[1]  = 16'd337;   // 0.020552684
        coeff_rom[2]  = 16'd465;   // 0.028396631
        coeff_rom[3]  = 16'd621;   // 0.037923047
        coeff_rom[4]  = 16'd808;   // 0.049296639
        coeff_rom[5]  = 16'd1027;  // 0.062671826
        coeff_rom[6]  = 16'd1281;  // 0.078188509
        coeff_rom[7]  = 16'd1572;  // 0.095967794
        coeff_rom[8]  = 16'd1902;  // 0.116107786
        coeff_rom[9]  = 16'd2272;  // 0.138679546
        coeff_rom[10] = 16'd2682;  // 0.163723333
        coeff_rom[11] = 16'd3133;  // 0.191245225
        coeff_rom[12] = 16'd3624;  // 0.221214225
        coeff_rom[13] = 16'd4154;  // 0.253559961
        coeff_rom[14] = 16'd4721;  // 0.288171034
        coeff_rom[15] = 16'd5323;  // 0.324894126
        coeff_rom[16] = 16'd5956;  // 0.363533898
        coeff_rom[17] = 16'd6617;  // 0.403853725
        coeff_rom[18] = 16'd7300;  // 0.445577304
        coeff_rom[19] = 16'd8002;  // 0.488391123
        coeff_rom[20] = 16'd8715;  // 0.531947770
        coeff_rom[21] = 16'd9435;  // 0.575870065
        coeff_rom[22] = 16'd10154; // 0.619755930
        coeff_rom[23] = 16'd10866; // 0.663183933
        coeff_rom[24] = 16'd11563; // 0.705719403
        coeff_rom[25] = 16'd12238; // 0.746921012
        coeff_rom[26] = 16'd12884; // 0.786347677
        coeff_rom[27] = 16'd13493; // 0.823565670
        coeff_rom[28] = 16'd14060; // 0.858155769
        coeff_rom[29] = 16'd14577; // 0.889720317
        coeff_rom[30] = 16'd15039; // 0.917890027
        coeff_rom[31] = 16'd15439; // 0.942330394
        coeff_rom[32] = 16'd15774; // 0.962747575
        coeff_rom[33] = 16'd16038; // 0.978893597
        coeff_rom[34] = 16'd16230; // 0.990570797
        coeff_rom[35] = 16'd16345; // 0.997635377
        coeff_rom[36] = 16'd16384; // 1.0 (Center tap)
    end

    logic [5:0] read_addr;
    logic compute_en;
    logic [2:0] pipe_valid;

    logic signed [13:0] pre_add_reg; 
    logic signed [15:0] coeff_reg;
    logic signed [29:0] mult_reg;    
    logic signed [35:0] accum_reg;   
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < TAPS; i++) begin
                shift_reg[i] <= '0;
            end
        end else if (data_valid_in) begin
            shift_reg[0] <= data_in;
            for (int i = 1; i < TAPS; i++) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_addr <= '0;
            compute_en <= 1'b0;
        end else begin
            if (data_valid_in) begin
                compute_en <= 1'b1;
                read_addr <= '0;
            end else if (compute_en) begin
                if (read_addr == FOLDED_TAPS - 1) begin
                    compute_en <= 1'b0; 
                end else begin
                    read_addr <= read_addr + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pre_add_reg <= '0;
            coeff_reg <= '0;
            mult_reg <= '0;
            accum_reg <= '0;
            pipe_valid <= '0;
            data_out  <= '0;
            data_valid_out <= 1'b0;
        end else begin
            pipe_valid[0] <= compute_en;
            pipe_valid[1] <= pipe_valid[0];
            pipe_valid[2] <= pipe_valid[1];
            
            if (compute_en) begin
                if (read_addr == 6'd36) begin
                    pre_add_reg <= shift_reg[read_addr];
                end else begin
                    pre_add_reg <= shift_reg[read_addr] + shift_reg[TAPS - 1 - read_addr];
                end
                coeff_reg <= coeff_rom[read_addr];
            end

            if (pipe_valid[0]) begin
                mult_reg <= pre_add_reg * coeff_reg;
            end

            data_valid_out <= 1'b0; 

            if (pipe_valid[1]) begin
                if (!pipe_valid[2]) begin
                    accum_reg <= mult_reg; 
                end else begin
                    accum_reg <= accum_reg + mult_reg;
                end
            end

            if (pipe_valid[2] && !pipe_valid[1]) begin
                data_out <= accum_reg[26:11]; 
                data_valid_out <= 1'b1;
            end
        end
    end
endmodule