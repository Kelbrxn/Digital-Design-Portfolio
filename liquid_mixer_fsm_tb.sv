module liquid_mixer_tb;

  // Clock and reset
  logic clk;
  logic rst;

  // Inputs
  logic x0;    // start
  logic x1;    // low-level sensor
  logic x2;    // high-level sensor
  logic x10;   // emergency

  // Outputs
  logic y0;    // liquid A valve
  logic y1;    // liquid B valve
  logic y2;    // drainage valve
  logic y3;    // mixer motor

  // Counter interface
  logic [7:0] counter;
  logic counter_done;
  logic enable;
  logic load;
  logic direction;
  logic [7:0] load_value;

  // ------------------------------------------------------------------------
  // DUT instantiation
  // ------------------------------------------------------------------------
  liquid_mixer #(.WIDTH(8)) DUT (
    .clk(clk),
    .rst(rst),
    .x0(x0),
    .x1(x1),
    .x2(x2),
    .x10(x10),
    .y0(y0),
    .y1(y1),
    .y2(y2),
    .y3(y3),
    .counter(counter),
    .counter_done(counter_done),
    .enable(enable),
    .load(load),
    .direction(direction),
    .load_value(load_value)
  );

  // ------------------------------------------------------------------------
  // Clock generation
  // ------------------------------------------------------------------------
  initial clk = 0;
  always #10 clk = ~clk;

  // ------------------------------------------------------------------------
  // Task: Start Button
  // ------------------------------------------------------------------------
  task automatic start_button();
    begin
      x0 <= 1;
      @(posedge clk);
      x0 <= 0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Task: Low Level Sensor
  // ------------------------------------------------------------------------
  task automatic low_level_sensor();
    begin
      x1 <= 1;
      @(posedge clk);
      x1 <= 0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Task: High Level Sensor
  // ------------------------------------------------------------------------
  task automatic high_level_sensor();
    begin
      x2 <= 1;
      @(posedge clk);
      x2 <= 0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Task: Liquid Mixing
  // ------------------------------------------------------------------------
  task automatic liquid_mixing();
    begin
      @(posedge clk);
      load       <= 1;
      load_value <= 0;

      @(posedge clk);
      load   <= 0;
      enable <= 1;
      direction <= 1;

      // Wait synchronously for counter to finish
      while (!counter_done) @(posedge clk);

      @(posedge clk);
      enable <= 0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Task: Liquid Draining
  // ------------------------------------------------------------------------
  task automatic liquid_draining();
    begin
      @(posedge clk);
      load       <= 1;
      load_value <= 0;

      @(posedge clk);
      load   <= 0;
      enable <= 1;
      direction <= 1;

      // Wait synchronously for counter to finish
      while (!counter_done) @(posedge clk);

      @(posedge clk);
      enable <= 0;
    end
  endtask

endmodule


