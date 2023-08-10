`timescale 1ns / 1ps
module test();
    reg             clk,rst_n;
    reg             decode_en;
    reg [203:0]     code;
    
    wire [203:0]    out;
    wire            done;
    wire            error;
    wire            busy;
    wire    [2:0]   s;
    wire    [2:0]   s_next;
    wire    [4:0]   iteration_num;
    
    initial begin 
        #0      code <= {9'b000001011,{195{1'b0}}}; 
        #1500   code <= {27'b000_0010_0010_0001_0000_0000_0001 , {177{1'b0}}}; 
    end
    
    initial begin 
        #0     decode_en <= 1; 
        #200   decode_en <= 0;
        #1700  decode_en <= 1;
        #200   decode_en <= 0; 
    end
    
    initial begin #0 clk <= 0; end
    always begin #50 clk <= ~clk; end
    
    initial begin 
        #0      rst_n <= 1;
        #20     rst_n <= 0;
        #100    rst_n <= 1;
    end
    
    ldpc_decoder_bf decoder(
        .clk(clk),
        .rst_n(rst_n),
        .decode_en(decode_en),
        .code(code),
        .out(out),
        .done(done),
        .busy(busy),
        .error(error),
        .st_cur(s),
        .st_next(s_next),
        .iteration_num(iteration_num)
    );
endmodule