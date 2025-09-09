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
