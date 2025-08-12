module counter(
    input logic clk,
    input logic rst,
    output logic [3:0] counter
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
    end
    else
    begin
        counbter <= counter + 1;
    end
end
endmodule

module counter_tb;
logic clk;
logic rst;
logic [3:0] counter;
counter DUT(
    .clk(clk),
    .rst(rst),
    .counter(counter)
);
initial begin
    clk = 0;
end
always begin
    #10 clk = ~clk;
end
initial begin
    rst = 1;
    $display("time=%0t, rst=%b, counter=%d", $time, rst, counter);
    #5
    rst = 0;
    $display("time=%0t, rst=%b, counter=%d", $time, rst, counter);
    #10 
$display("time=%0t, rst=%b, counter=%d", $time, rst, counter);
$finish;
end
endmodule