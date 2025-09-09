
module counter #(parameter WIDTH = 8) (
    input logic clk,
    input logic rst,
    output logic [WIDTH-1:0] counter,
    input logic enable,
    input logic load,
    input logic [WIDTH-1:0] load_value,
    input logic direction
);
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
    end 
    else if (load) begin
        counter <= load_value;
    end 
    else if (enable) begin
        if (direction) begin
            counter <= counter + 1;    // Count up
        end 
      	else begin
            counter <= counter - 1;    // Count down  
        end
    end
    // If none of the above conditions are met, counter holds its value
end
endmodule
