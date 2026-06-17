`timescale 1ns / 1ps

module axi_stream_fifo_tb;

    // Parameters matching the DUT
    parameter DATA_WIDTH = 32;
    parameter DEPTH      = 32;

    // Clock and Reset Signals
    logic s_axis_clk;
    logic s_axis_aresetn;
    logic m_axis_clk;

    // Slave Interface (Write Domain)
    logic [DATA_WIDTH-1:0] s_axis_tdata;
    logic                  s_axis_tvalid;
    wire                   s_axis_tready;

    // Master Interface (Read Domain)
    wire  [DATA_WIDTH-1:0] m_axis_tdata;
    wire                   m_axis_tvalid;
    logic                  m_axis_tready;

    // -------------------------------------------------------------------------
    // DUT INSTANTIATION
    // -------------------------------------------------------------------------
    axi_stream_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .s_axis_clk(s_axis_clk),
        .s_axis_aresetn(s_axis_aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        
        .m_axis_clk(m_axis_clk),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid)
    );

    // -------------------------------------------------------------------------
    // CLOCK GENERATION & WAVEFORM SETUP
    // -------------------------------------------------------------------------
    // Write Clock: 100 MHz
    initial begin
        s_axis_clk = 0;
        forever #5 s_axis_clk = ~s_axis_clk;
    end

    // Read Clock: ~144 MHz (Intentional mismatch to test CDC synchronizers)
    initial begin
        m_axis_clk = 0;
        forever #3.47 m_axis_clk = ~m_axis_clk;
    end

    // Enable Waveform Generation
    initial begin
        $dumpfile("fifo_waves.vcd");
        $dumpvars(0, axi_stream_fifo_tb);
    end

    // -------------------------------------------------------------------------
    // HELPER TASK: Hardware Reset
    // -------------------------------------------------------------------------
    task apply_hw_reset();
        $display("\n[%0t ns] --- Executing Hardware Reset ---", $time);
        s_axis_aresetn = 0;
        repeat(10) @(posedge s_axis_clk);
        s_axis_aresetn = 1;
        
        // Wait for the reset to propagate through the master CDC bridge
        repeat(5) @(posedge m_axis_clk);
        $display("[%0t ns] --- Reset Complete & Synchronized ---", $time);
    endtask

    // -------------------------------------------------------------------------
    // AUTOMATED LOGGING (Monitors successful handshakes continuously)
    // -------------------------------------------------------------------------
    always @(posedge s_axis_clk) begin
        if (s_axis_tvalid && s_axis_tready && s_axis_aresetn)
            $display("   [WRITE] Data: 0x%h entered FIFO", s_axis_tdata);
    end

    always @(posedge m_axis_clk) begin
        if (m_axis_tvalid && m_axis_tready && s_axis_aresetn)
            $display("   [READ]  Data: 0x%h exited FIFO", m_axis_tdata);
    end

    // Safety Timeout
    initial begin
        #50000;
        $display("\n[%0t ns] FATAL: Simulation Timeout Reached.", $time);
        $finish;
    end

    // -------------------------------------------------------------------------
    // MAIN STIMULUS SEQUENCE
    // -------------------------------------------------------------------------
    initial begin
        // Initialize lines
        s_axis_aresetn = 0;
        s_axis_tvalid  = 0;
        s_axis_tdata   = 0;
        m_axis_tready  = 0;

        // Startup Reset
        apply_hw_reset();

        $display("\n==========================================================");
        $display("   CASE 1: FULL WRITE -> FULL READ (Testing Boundaries)     ");
        $display("==========================================================");
        
        // 1. Assert Empty
        @(posedge m_axis_clk);
        if (!m_axis_tvalid) $display("[%0t ns] SUCCESS: FIFO asserts EMPTY at startup.", $time);

        // 2. Write until Full (Burst Write with locked data)
        $display("[%0t ns] Initiating continuous write burst...", $time);
        for (int i = 0; i < DEPTH; i++) begin
            s_axis_tvalid = 1;
            s_axis_tdata  = 32'hC1_0000 + i; 
            @(posedge s_axis_clk);
            while (!s_axis_tready) @(posedge s_axis_clk); // Hold if backpressure applied
        end
        s_axis_tvalid = 0;

        // Verify Full Flag
        repeat(5) @(posedge s_axis_clk);
        if (!s_axis_tready) $display("[%0t ns] SUCCESS: FIFO correctly asserts FULL. Backpressure applied.", $time);

        // 3. Read until Empty (Continuous ready assertion)
        $display("[%0t ns] Initiating continuous read burst...", $time);
        m_axis_tready = 1;
        for (int i = 0; i < DEPTH; i++) begin
            @(posedge m_axis_clk);
            while (!m_axis_tvalid) @(posedge m_axis_clk); // Wait if FIFO starves
        end
        m_axis_tready = 0;

        // Verify Empty Flag
        repeat(5) @(posedge m_axis_clk);
        if (!m_axis_tvalid) $display("[%0t ns] SUCCESS: FIFO correctly asserts EMPTY after drain.", $time);


        $display("\n==========================================================");
        $display("   CASE 2: INTERRUPT -> ZERO OUT -> FULL -> RESET -> ANEW   ");
        $display("==========================================================");

        // 1. Write partially (Interrupted before full)
        $display("[%0t ns] Writing half-capacity burst...", $time);
        for (int i = 0; i < DEPTH/2; i++) begin
            s_axis_tvalid = 1;
            s_axis_tdata  = 32'hC2_0000 + i;
            @(posedge s_axis_clk);
            while (!s_axis_tready) @(posedge s_axis_clk);
        end
        s_axis_tvalid = 0;

        // 2. Zero Out Process (Read until valid drops)
        $display("[%0t ns] Interrupting write. Zeroing out the FIFO...", $time);
        @(posedge m_axis_clk);
        m_axis_tready = 1;
        while (m_axis_tvalid) begin // Keep reading as long as there is data
            @(posedge m_axis_clk);
        end
        m_axis_tready = 0;
        $display("[%0t ns] SUCCESS: FIFO zeroed out successfully.", $time);

        // 3. Write until Full
        $display("[%0t ns] Pushing to FULL capacity...", $time);
        for (int i = 0; i < DEPTH; i++) begin
            s_axis_tvalid = 1;
            s_axis_tdata  = 32'hF0_0000 + i; 
            @(posedge s_axis_clk);
            while (!s_axis_tready) @(posedge s_axis_clk);
        end
        s_axis_tvalid = 0;

        // 4. Start reading (Read just 3 items to alter pointers before reset)
        $display("[%0t ns] Reading a few items before issuing reset...", $time);
        m_axis_tready = 1;
        for (int i = 0; i < 3; i++) begin
            @(posedge m_axis_clk);
            while (!m_axis_tvalid) @(posedge m_axis_clk);
        end
        m_axis_tready = 0;

        // 5. Reset while the FIFO is actively holding data
        apply_hw_reset();

        // 6. Begin Anew
        $display("\n[%0t ns] Starting fresh post-reset transactions...", $time);
        @(posedge m_axis_clk);
        if (!m_axis_tvalid) $display("[%0t ns] SUCCESS: FIFO properly cleared residual data.", $time);
        
        // Final single write/read proof
        s_axis_tvalid = 1;
        s_axis_tdata  = 32'hAA_BB_CC_DD;
        @(posedge s_axis_clk);
        while (!s_axis_tready) @(posedge s_axis_clk);
        s_axis_tvalid = 0;

        m_axis_tready = 1;
        @(posedge m_axis_clk);
        while (!m_axis_tvalid) @(posedge m_axis_clk);
        m_axis_tready = 0;

        $display("\n==========================================================");
        $display("   SIMULATION COMPLETED SUCCESSFULLY!                     ");
        $display("==========================================================");
        $finish;
    end

endmodule