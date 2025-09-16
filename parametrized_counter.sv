module counter #(parameter WIDTH = 8) (
    input  logic clk,
    input  logic rst,
    output logic [WIDTH-1:0] counter,
    input  logic enable,
    input  logic load,
    input  logic [WIDTH-1:0] load_value,
    input  logic direction,
    output logic counter_done
);

  // sequential counter
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      counter      <= 0;
      counter_done <= 0;
    end 
    else begin
      counter_done <= 0;  // default each cycle

      if (load) begin
        counter <= load_value;
      end 
      else if (enable) begin
        if (direction) begin
          counter <= counter + 1;   // Count up
          if (counter == 8'd59)     // will become 60 next
            counter_done <= 1;      // pulse high for 1 cycle
        end 
        else begin
          counter <= counter - 1;   // Count down
          if (counter == 1)         // will become 0 next
            counter_done <= 1;      // pulse high for 1 cycle
        end
      end
    end
  end
endmodule

