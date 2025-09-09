module counter_tb;
    logic clk;
    logic rst;
    logic [7:0] counter;
    logic enable;
    logic load;
    logic [7:0] load_value;
    logic direction;
    
    counter #(.WIDTH(8)) DUT(
        .clk(clk),
        .rst(rst),
        .counter(counter),
        .enable(enable),
        .load(load),
        .load_value(load_value),
        .direction(direction)
    );
    
    initial begin
        clk = 0;
    end
    
    always begin
        #10 clk = ~clk;
    end
    
    initial begin
        rst = 1;
     	load=0;
     	load_value=0;
      	direction=0;
      	enable=0;
    	#5
        rst = 0;
        load_value = 10;
        #15
        direction = 1;
        enable = 1;
        #100
      	rst = 1;
    	enable = 0;
      	direction=0;
      	#5
      	rst = 0;
      	#5
        load = 1;
        #5
        load = 0;
      	enable=1;
            direction = 0;
        #200
        rst = 1;
        #5
        rst = 0;
        #5
        direction = 1;
        enable = 1;
        #5
        #100
        rst = 1;
        #5
        rst = 0;
        #5
        $finish;
    end
    
initial begin
  $dumpfile("counter.vcd");
  $dumpvars(0, counter_tb);
end
endmodule
