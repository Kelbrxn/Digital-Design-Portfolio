module top_module #(
    parameter WIDTH = 8   // default, can be overridden at instantiation
)(
  input logic clk,
  input logic rst,
  input logic x0,//start 
  input logic x1,//lower level sensor
  input logic x2,//higher level sensor
  input logic x10,//emergency
  output logic y0,//liquid A valve
  output logic y1,//liquid B valve
  output logic y2,//Drainage valve
  output logic y3//mixer motor
);
  
  
//wire declaration
  logic [WIDTH-1:0] counter;
  logic counter_done;
  logic enable;
  logic load;
  logic direction;
  logic [WIDTH-1:0] load_value;
  
  
//fsm enumeration
typedef enum logic [2:0] {
    IDLE      = 3'b000,
    FILL_A    = 3'b001,
    FILL_B    = 3'b010,
    MIXING    = 3'b011,
    DRAINING  = 3'b100,
    COMPLETE  = 3'b101,
    EMERGENCY = 3'b111
} state_t;
  
  
//state transition name declaration
state_t previous_state , current_state, next_state;


//state_transition pulse for counter load on mixing and draining 
always_ff @(posedge clk or negedge rst) begin
if (!rst) begin
previous_state <= IDLE ;
end
else begin
previous_state <= current_state;
end
end
always_comb begin
if ((current_state == MIXING || current_state == DRAINING) && (previous_state != current_state)) begin
load = 1;
end
else begin
load = 0;
end
end
  

//counter instantiation
  counter #(.WIDTH(WIDTH)) u_counter(
    .clk(clk),
    .rst(rst),
    .counter(counter),
    .counter_done(counter_done),
    .enable(enable),
    .load(load),
    .direction(direction),
    .load_value(load_value)
  );
  
  
// Sequential state register
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        current_state <= IDLE;
  else if (~x10) begin
      current_state <= next_state;
  end
end

  
//combinational block for state transitions
always_comb begin
    // Default outputs (safe)
    y0 = 0;  // valve A
    y1 = 0;  // valve B
    y2 = 0;  // drain
    y3 = 0;  // mixer
    enable = 0;
    direction = 1;
    next_state = current_state;

  if (!x10) begin
    case (current_state)
      
        IDLE: begin
            if (x0) 
                next_state = FILL_A;
        end

      
        FILL_A: begin
            y0 = 1; // open valve A
            if (x1) 
                next_state = FILL_B;
        end

      
        FILL_B: begin
            y1 = 1; // open valve B
            if (x2)  // upper sensor
                next_state = MIXING;
        end

      
        MIXING: begin
            y3 = 1; // start mixer
          enable = 1;
          load_value = 0;
          direction = 1;
          if (counter_done) 
                next_state = DRAINING;
        end

      
        DRAINING: begin
            y2 = 1; // open drain
           enable = 1;
          load_value = 0;
          direction = 1;
          if (counter_done) 
                next_state = COMPLETE;
        end

      
        COMPLETE: begin
            // optional: wait for counter or ack
            if (counter_done) 
                next_state = IDLE;
        end
      
    endcase
  end
endmodule
