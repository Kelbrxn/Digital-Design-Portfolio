
module counter #(parameter WIDTH = 8) (
    input logic clk,
    input logic rst,
    output logic [WIDTH-1:0] counter,
    input logic enable,
    input logic load,
    input logic [WIDTH-1:0] load_value,
    input logic direction
    output logic done
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
      // "done" flag logic
  always_comb begin
    if (!direction && counter == 0)        // reached 0 on down-count
        done = 1;
    else if (direction && counter == {WIDTH{1'b1}})  // reached max on up-count
        done = 1;
    else
        done = 0;
  end
endmodule
