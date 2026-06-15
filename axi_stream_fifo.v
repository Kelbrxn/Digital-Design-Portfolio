`timescale 1ns / 1ps

module axi_stream_fifo #(
    parameter   DATA_WIDTH=          32,
    parameter   DEPTH=               32
)(
    //Master Signals

    input  wire                      m_axis_clk,
    input                            m_axis_tready,
    output wire [DATA_WIDTH-1:0]     m_axis_tdata,
    output wire                      m_axis_tvalid,


    //Slave Signals

    input  wire                      s_axis_clk,
    input  wire                      s_axis_aresetn,
    input  wire [DATA_WIDTH-1:0]     s_axis_tdata,
    input  wire                      s_axis_tvalid,
    output wire                      s_axis_tready

);
//register array to implement FIFO
reg [DATA_WIDTH-1:0] fifo_array [DEPTH-1:0];

//write and read pointers in binary and gray code
reg [$clog2(DEPTH):0] w_ptr_binary, w_ptr_gray, r_ptr_binary, r_ptr_gray;

//cross domain sync register, sync0 is responsible for metastability and sync1 is responsible for data transfer
reg [$clog2(DEPTH):0] w_ptr_gray_sync0, w_ptr_gray_sync1, r_ptr_gray_sync0, r_ptr_gray_sync1;

//internal reset synchronization registers for master cdc
reg s_axis_aresetn_sync0, s_axis_aresetn_sync1;

//internal signals for fifo full and empty flags
wire fifo_full, fifo_empty;


assign s_axis_tready = ~fifo_full; //slave is ready to accept data when fifo is not full
assign m_axis_tvalid = ~fifo_empty; //master has valid data to send when fifo is not empty
assign m_axis_tdata = fifo_array[r_ptr_binary[$clog2(DEPTH)-1:0]]; //master data is the data at the read pointer location in the fifo array

//Master reset synchronization process
always @(posedge m_axis_clk) begin
    s_axis_aresetn_sync0 <= s_axis_aresetn; //first stage of reset synchronization
    s_axis_aresetn_sync1 <= s_axis_aresetn_sync0;//second stage of reset synchronization
end

//Write pointer logic in slave clock domain
always @(posedge s_axis_clk) begin
    if(!s_axis_aresetn) begin
        w_ptr_binary <= 0; //reset write pointer to 0
        w_ptr_gray <= 0; //reset write pointer in gray code to 0
    end else if(s_axis_tvalid && s_axis_tready) begin
        fifo_array[w_ptr_binary[$clog2(DEPTH)-1:0]] <= s_axis_tdata; //write data to fifo array at the location pointed by write pointer
        w_ptr_binary <= w_ptr_binary + 1; //increment write pointer in binary
        w_ptr_gray <= (w_ptr_binary + 1) ^ ((w_ptr_binary + 1) >> 1); //update write pointer in gray code
    end
end

// r_ptr_gray synchronization to slave clock domain
always @(posedge s_axis_clk) begin
    if (!s_axis_aresetn) begin
        r_ptr_gray_sync0 <= 0; 
        r_ptr_gray_sync1 <= 0; 
    end else begin
        r_ptr_gray_sync0 <= r_ptr_gray; // first stage of read pointer gray code synchronization
        r_ptr_gray_sync1 <= r_ptr_gray_sync0; // second stage of read pointer gray code synchronization
    end
end

//full flag logic: fifo is full when the next write pointer in gray code is equal to the read pointer in gray code with the most significant bit inverted
assign fifo_full = (w_ptr_gray == {~r_ptr_gray_sync1[$clog2(DEPTH):$clog2(DEPTH)-1], r_ptr_gray_sync1[$clog2(DEPTH)-2:0]});

//Read pointer logic in master clock domain
always @(posedge m_axis_clk) begin
    if(!s_axis_aresetn_sync1) begin
        r_ptr_binary <= 0; //reset read pointer to 0
        r_ptr_gray <= 0; //reset read pointer in gray code to 0
    end else if(m_axis_tvalid && m_axis_tready) begin
        r_ptr_binary <= r_ptr_binary + 1; //increment read pointer in binary
        r_ptr_gray <= (r_ptr_binary + 1) ^ ((r_ptr_binary + 1) >> 1); //update read pointer in gray code
    end
end

//w_ptr_gray synchronization to master clock domain
always @(posedge m_axis_clk) begin
    if (!s_axis_aresetn_sync1) begin
        w_ptr_gray_sync0 <= 0; //reset sync0 register to 0
        w_ptr_gray_sync1 <= 0; //reset sync1 register to 0
    end else begin
        w_ptr_gray_sync0 <= w_ptr_gray; //first stage of write pointer gray code synchronization
        w_ptr_gray_sync1 <= w_ptr_gray_sync0; //second stage of write pointer gray code synchronization
    end
end

//empty flag logic: fifo is empty when the read pointer in gray code is equal to the write pointer in gray code
assign fifo_empty = (r_ptr_gray == w_ptr_gray_sync1);

endmodule