`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/05 15:19:14
// Design Name: 
// Module Name: ldpc_decoder_bf
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ldpc_decoder_bf
#()
(
    input clk,
    input rst_n,

    input decode_en,
    input [N-1:0] code,
    
    output reg [N-1:0] out,
    output reg done,
    output reg error,
    output reg busy,

    // for debug
    output reg [2:0] st_cur,
    output reg [2:0] st_next,
    output reg [4:0] iteration_num 
);
    parameter           M = 102 ; // row number of H
    parameter           N = 204; // column number of H
    //machine state decode
    parameter            IDLE   = 3'd0 ;
    parameter            CALCULATE1  = 3'd1 ;
    parameter            CLACULATE2  = 3'd3 ;
    parameter            CHECK1     =  3'd2;
    parameter            CHECK2 = 3'd4;  
    parameter            ERROR  = 3'd5 ;
    parameter            DONE   = 3'd6 ;
    // code register
    reg [N-1:0] code_reg;
    //state machine variable
    //reg [2:0]            st_next ;
    // check matrix H
    reg [N*M-1:0] H ;
    reg [N*M-1:0] H_T ; // trnaspose matrix
    always @(*) begin
        H <= 20808'b000000000000000000000000010100000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010000010000000000000000000000000000000000000000000000000000000000100000000000000010000000000000010000000000000000000000000000000000000000000001000100000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000001000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000010000000010000000000000000000000010000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000010000001000000000000000000000000000000000000000000100001000000100000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000100000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000100000000000000010000000000000000000000000000000000000000000000000000010000010000000000000000000000000000000000000000001000000000000000000000000000010000000000000000001000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000001000000000000000000000000000000010000000000000000000000100000000000000000000000000000000010000000000000000000100000000000000000000000000001000000000000000000000010000000000000000000000000000000000000000000000010000000010000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000100010000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000010000001000000000000000000000000000000000000000000000000000000010000000000000000000010000000000000010000000000000000000000000000000000000100000000000000000000100000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000001000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000100000000000100000000001000000000000000000100000000000000000000000000000000000000000000000000000000001000000000000000000010000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000100000000000001000000000000000000000000000000000001000000000001000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000000000000000000000000000000000000100010000000000010000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000001000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000100000000000000000000100000000000000000000000010000000000000000000000100000000000000000000000000000000000000000000000010000000001000000000000000000000000000000010000000000000000000000000000000000000000000001000000000000000000000100000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000010000000000010000000001000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000100001000000000000000000000000000000000000000000000100000000000000000000000000000000000001000000000000000000000100000000000000000000000000000000000000000000000000000000001100000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000100000000001000000000000000000000000000000000000000000100000000000010000000000000000000000000000000000000000000000010000000000000000000000000000000001000000000000000000010000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000100000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000100000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000100000000000010000000000000000000001000000000000000000000000000000000000000000000000100000000000000000010000000000000000000000000000000000000000000000000100000000000000000000000000100000000000010000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000010000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000010000000000100000000000000000000000000000000000000100000000000000000000000000000010000010000000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000100000000000010000000000000000000000000000000000000100000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000010000000000000000000000000000000000100000010000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000100100000000000000000000000000000000000000100000000000000000000000000000000000000000000010000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000010000000000000000000000000001000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000001000000000010000000000000100000000000000000000000000000000000000001000000000010000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000001000000000000000000000100000000000000000000000000010000000000000000000000000000000000000000000010010000000000000000000000000000000000000000000001000000000000000000000000000000000000000000100100000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000011000001000000000000000000000000000000000000000000100000000000000000000000100000000000000000000000000000000000000000010000000000000010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000001000000000000000000000001000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000010000000000000000000000000010000001000000000000000000000100000000000000000000000000000000000000000010000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000001000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000010000000000100000000000000000000000000000000000000001100000010000000000000000000000000000000000000000000000000000000000000000001000000000000100000000000000000000000000000000000100000000000000000000000000000000000000000000000100000000000000000010000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000001000000000000000000000000000000000000000000000000010000000100000000000000000000000000000000000100000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000001000000000000000000000000100000000000000000000000000000001000000000000000000000000000000000000000010000000000000000000000000000000001000001000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000001000100000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000000000100000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000010000000001000000001000000001000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000001000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000010000001000000001000000000001000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000010000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000000000000000000000100000000000000100000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000001000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000011000000000000000000000000000000000000000000000000000000001000001000000000000000000000000000000000000000000100000000000100000000000000000000000000000000000000000000000000000000000100000100000000000000000000000000000000000000000000000000000000000000000000000000000000100100000000000000000000010000000000000000000000000000000000000000000010000000000000000010000000000000000000000000000000000000000000000000000000010000000000000001000000000000000000000000000000000000000000001000001000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000100000000000000000000000000000000010000000000000000000000001000000000000010000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000010000000001000000001000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000010000000000000000000000000001000000000000000000000000000000000000000000000100000000000000000000001000000000000000000000000000000000000000000000000000001000000000000000000000000000000000010000100000000000000010000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000010000000000000000001000000000000000000000000000000010000000000000000000000001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000000000100000000000001000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000010000000000000000000100010000000000000000000000000000000000000010000000000000000000000000000000000000100000000000000000000000000000010000000000000000000000000001000000000000000000000000000000000000000001000000000000010000000000000000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000001000000000010000100000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000010000000000010000000000000000000000000000000000000000000000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000000000000100000000000000000000000000000000000000000000010000000000000000000000000000000100000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000010001001000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000001000000000000000000010000000000000010000000001000000000000000000000000000000000000000000000000000000000000000000000000000000001000000101000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000001000000000000000000000000000100000000000000000000000000100010000000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000001000000000000000100000000000000000000000000000000000100000000000000000000001000000000000000000000000000000000000000000000000000000000000001000000010001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000100000000000000001000000000000000000000000000001000000000000000000000000000000000000000000000000000000001000000000100000001000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000010000000001000000000000000000000000000000001000000000000000000000000000000000000000100000000000000001000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000010000100000000000000000000000000000000000100100000000000000000000000000000000001000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000100000000010000000000000000000000000001000000001000000000000000000000000000000001000000000000000000000000000000000000000000000000100000000000000000000000000010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000010000000000001000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000001000000100000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000001000000000010000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000001000000000000000000010000000000000000000000000000000000000000000000000000000000000000000100010000000000000000000100000000000000000000000100000000000000000000000000000100000000100000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000100000000000000000000000000010000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000010001000000000000000000100000000000000000000000000000000000000000100000000000000000000000000001000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000100001000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000100000000001000000000000100000000000000000000000000000001000000000000000000000000000000000000000000000000100000000000000000000000000000000100000000000000000000000001000010000000000000000000000000000000000000000000000000000000000000000000000100000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000010000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000001000000100000000000000000010000000000000000000000000000000000000000000000100000000000000000010000000000000000000000000000000000000000000000000000000000000000001000000000000001000000000100000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000000100000000000000000000000000000000000000000000000100000000001000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010010000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000010000000000000000000100000000000100000000000000000000000000000000000000000000000000000000000000000010000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000100000000001100000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000001000000000000000000000000000000000000000000100000000000000000000001000000000001000000000000000001000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000010000100000000000000000000000000000000000100000010000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010001000000000000100000000000000000000000100000000000000000000000000000000000000001000000000000000000000000000000000000000000000000100000000000000010000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000010000000001000000000000000000000000000000000100000000000000000000000000000000100000000000000000000000000000000001000000000000000000000000001000000000000000000000000000000000000000000000000100000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000001000010000000000000000000000000000000000000000000000000000000000001000000000000000010000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000100000000000000000000000000001000000000010000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000010000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000100000000000000000000000000000000000001000000000000000000000000000000000000000000000000100000000000000000000000000000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000100001000000000000000000000000000000000000000000000000000010000000000010000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000001000000000000000000100000000000000000000000000000000000000000000000000010000000000000000000100000000000000000000000000000100000000000000000000000000000000000000001000000000000000000000000000000000000000000001000000100000000000000000000010000000000000000000000000000000000000000000000010000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000100000000100000000000000000000000000000000000000000000000000000000000000000000010000000000000000000001000000000000000010000000000000000000000000000000000000000000000000000000010010000000000100000000000000000000000000000000000000000000000001000000000000000000000000000010000000000000000000000000000000000100000000000000000000000000000000000000010000000000000000000000000000000000000000000000010001000000000000000000000000000000000000100000000000000000001000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000100000000010000000000000000000000000000000010000000000000000000000000000000000000000001000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000000100000000000000000000000010000000100000000000000001000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000100000000000000000000000000000000000100000000000000001000000000000000000000000000000000000000000000000000000000000010000010000000000000000000000000000000010000000010000000000000000000000000000000000000000000000001000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000001001000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000100000000100000000000000000000010000000000000000000000100010000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000001000000000000000000000000000000000000100000000000000000000000000000000000000000000000000010000000000000000000000000000010000000000000100000000000000000000;

        // generate transpose matrix
        for (integer row = 0; row <= M; row = row + 1) begin
            for (integer col = 0; col <= N; col = col + 1)begin
                H_T[col*M+row] <= H[row*N+col];
            end
        end

        code_reg <= code; // 赋值
    end
    
    // section 1
    // state transfer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            st_cur <= IDLE;
        else
            st_cur <= st_next;
    end

    // section 2
    // state switch, using block assignment for combination-logic
    // all case items need to be displayed completely
    reg     [M-1:0] judge; //
    wire    [M-1:0] judge_wire;

    reg     [2:0]       count  [N - 1 : 0]; // TODO: why? 3 bits
    reg     [N - 1 : 0] flip_flag;
    always @(*) begin
        case(st_cur)
            
            IDLE:       st_next = decode_en ? CALCULATE1: IDLE;

            CALCULATE1: st_next = CHECK1;

            CHECK1:     st_next = (judge_wire == 102'b0) ? DONE:CLACULATE2;

            CLACULATE2: st_next = CHECK2; 

            CHECK2:     st_next = (iteration_num == 5'd10) ? ERROR: CALCULATE1;
            
            DONE:       st_next=IDLE;

            ERROR:      st_next = IDLE;
            
            default:        st_next = IDLE;
        endcase
    end

    /*
    CALCULATE1
    */
    genvar m;
    generate
        for (m =0 ;m<M ;m=m+1 ) begin
            assign judge_wire[m] = (st_cur == CALCULATE1 || st_cur == CHECK1)? ^(code_reg & H[m*N+N-1:m*N]):102'b0;
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == 0)
            judge <= 102'b0;
        else if(done == 1 || error == 1)
            judge <= 102'b0;
        else if(st_cur == CALCULATE1)
            judge <= judge_wire;
    end
    /*
    CALCULATE2
    */
    reg     [M-1:0] wrong_matrix        [N-1:0]; 
    wire    [M-1:0] wrong_matrix_wire   [N-1:0];

    genvar n;
    generate
        for(n = 0 ; n < N ; n = n + 1)begin:calculate_wrong_num
            assign  wrong_matrix_wire[n] = (st_cur == CLACULATE2)?H_T[n * M + M - 1 : n * M] & judge:'{204{102'b0}};
        end
    endgenerate
    
    always@(posedge clk or negedge rst_n)begin
        if(rst_n == 0)
            wrong_matrix <= '{204{102'b0}};   
        else if(done == 1 || error == 1)
            wrong_matrix <= '{204{102'b0}};
        else if(st_cur == CLACULATE2)
            wrong_matrix <= wrong_matrix_wire;
    end

    // calculate turn flag
    reg [N-1:0] turn;
    reg [9:0] turn_count [N-1:0]; // 防止溢出

    always@(*)begin
        for(integer n = 0; n < N; n = n + 1)begin
            turn_count[n] = 3'd0;
            for(integer m = 0; m < M; m = m + 1)begin
                if(wrong_matrix[n][m] == 1'b1)begin
                    turn_count[n] = turn_count[n] + 3'd1;
                end
            end
        end
    end

    always@(*)begin
        for(integer n = 0; n < N; n = n + 1)begin
            turn[n] = 1'b0;
            turn[n] = (turn_count[n] > 10'd1) ? 1'b1 : 1'b0;
            if (turn[n]==1'b1) begin
                // flip
                code_reg[n] = ~code_reg[n];
            end
        end
        // iteration_num = iteration_num + 5'd1;
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n == 0)begin
            turn <= 204'd0;
            iteration_num <= 5'd0;
        end
        else if(done == 1 || error == 1)begin
            turn <= 204'd0;
            iteration_num <= 5'd0;
        end
        else if(st_cur == CHECK2)
            iteration_num <= iteration_num + 5'd1;
    end


    // section 3
    // generat out output
    always@(posedge clk or negedge rst_n)begin
        if(rst_n == 0)begin
            done <= 0;
            out <= {N{1'b1}};
        end
        else if(decode_en)
            out <= {N{1'b1}}; 
        else if(st_cur == DONE)begin
            out <= code_reg;
            done <= 1; 
        end
        else if(st_cur != DONE)begin
            out <= {N{1'b1}};
            done <=0;
        end
    end

    // generate error output
    always@(posedge clk or negedge rst_n)begin
        if(rst_n == 0)
            error <= 0;
        else if(st_cur == ERROR)
            error <= 1'b1;
        else begin
            error <= 0;
        end
    end
    
    // generate busy output
    always@(posedge clk or negedge rst_n)begin
        if(rst_n == 0)
            busy <= 0;
        else if(st_cur != IDLE)
            busy <= 1;
        else
            busy <= 0;
    end




endmodule