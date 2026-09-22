`timescale 1ns / 1ps

module fpga_top (
    input logic clk,   
    input logic rst_n, 
    input logic [6:0] sw,    
    output logic [15:0] led    
);

    localparam NUM_SAMPLES = 100;
    
    logic [6:0] us_counter; //micro second counter
    logic [6:0] write_addr;
    logic data_valid_in;
    logic signed [12:0] rom_data_out;
    
    logic signed [15:0] filter_data_out;
    logic filter_valid_out;

    logic [15:0] input_rom  [0:NUM_SAMPLES-1];
    logic [15:0] output_ram [0:NUM_SAMPLES-1];
    
    initial begin
        $readmemh("D:/Vivado _projects/LS_FIR_FILTER/input_samples.txt", input_rom);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            us_counter <= '0;
            write_addr <= '0;
            data_valid_in <= 1'b0;
        end else begin
            if (write_addr < NUM_SAMPLES) begin
                if (us_counter == 7'd99) begin 
                    us_counter <= '0;
                    data_valid_in <= 1'b1;  //data_valid_in asserted
                    rom_data_out <= input_rom[write_addr][12:0]; //storing inputs in ROM data_out
                end else begin
                    us_counter <= us_counter + 1'b1; //incrementing micro second counter
                    data_valid_in <= 1'b0; // deasserting data_valid_in
                end
                
                if (filter_valid_out) begin //data_valid_out signal in the fir_symmetric_pipelined 
                    write_addr <= write_addr + 1'b1;
                end
            end else begin
                data_valid_in <= 1'b0;
            end
        end
    end

// Design Instantiation
    fir_symmetric_pipelined uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_in(data_valid_in),
        .data_in(rom_data_out),
        .data_out(filter_data_out),
        .data_valid_out(filter_valid_out)
    );

// writing output memory
    always_ff @(posedge clk) begin
        if (filter_valid_out) begin
            output_ram[write_addr] <= filter_data_out;
        end
    end

//sw as address port and led as data_out from memory
    always_ff @(posedge clk) begin
        if (sw >= NUM_SAMPLES) begin
            led <= 16'd0;
        end else begin
            led <= output_ram[sw];
        end
    end

endmodule


