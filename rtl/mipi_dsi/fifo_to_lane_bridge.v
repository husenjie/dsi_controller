module fifo_to_lane_bridge (
    input   wire                clk                 ,    // Clock
    input   wire                rst_n               ,  // Asynchronous reset active low

    /********* input fifo iface *********/
    input   wire [7:0]          fifo_data           ,
    input   wire                fifo_empty          ,
    output  wire                fifo_read           ,

    input   wire                mode_lp_in          ,

    /********* Lane iface *********/
    output  wire                mode_lp             , // which mode to use to send data throught this lane. 0 - hs, 1 - lp
    output  wire                start_rqst          ,
    output  wire                fin_rqst            ,
    output  wire [7:0]          inp_data            ,
    input   wire                data_rqst

);

reg [7:0] middle_buffer;
reg       fifo_empty_delayed;
reg       state_active;
reg       mode_lp_reg;
wire [7:0] fifo_data_inv;

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin: lines_inversion
        assign fifo_data_inv[i] = fifo_data[7-i];
    end
endgenerate

always @(posedge clk)
    if(!rst_n)      fifo_empty_delayed <= 1'b0;
    else            fifo_empty_delayed <= fifo_empty;

assign start_rqst = (fifo_empty_delayed ^ fifo_empty) & !fifo_empty & !state_active & data_rqst;

always @(posedge clk)
    if(!rst_n)                  state_active <= 1'b0;
    else if(start_rqst)         state_active <= 1'b1;
    else if(fin_rqst)           state_active <= 1'b0;

always @(posedge clk)
    if(!rst_n)                  mode_lp_reg <= 1'b0;
    else if(fifo_read)          mode_lp_reg <= mode_lp_in;
    else if(fin_rqst)           mode_lp_reg <= 1'b0;

always @(posedge clk)
    if(!rst_n)                                          middle_buffer <= 1'b0;
    else if(start_rqst)                                 middle_buffer <= fifo_data_inv;
    else if(!fifo_empty && data_rqst && state_active)   middle_buffer <= fifo_data_inv;

assign fin_rqst     = (fifo_empty_delayed ^ fifo_empty) & fifo_empty & state_active;
assign mode_lp      = mode_lp_in;
assign fifo_read    = state_active & data_rqst & !fifo_empty | start_rqst;
assign inp_data     = middle_buffer;

endmodule