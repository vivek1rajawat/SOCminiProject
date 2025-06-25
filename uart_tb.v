`timescale 1ns/1ps
module tb_UART_System;

    reg clk, rst, wr_en, tx_start;
    reg [7:0] control_data, tx_data;
    reg rx_line;
    wire tx_line, tx_done, rx_done;
    wire [7:0] rx_data;

    UART_System uut (
        .clk(clk), .rst(rst), .wr_en(wr_en), .control_data(control_data),
        .tx_start(tx_start), .tx_data(tx_data),
        .rx_line(rx_line),
        .tx_line(tx_line), .rx_data(rx_data),
        .tx_done(tx_done), .rx_done(rx_done)
    );

    // 10ns clock
    always #5 clk = ~clk;

    // FIXED: Properly aligned with posedge clk
    task send_serial(input [7:0] data);
        integer i;
        begin
            @(posedge clk); rx_line = 0; // Start bit
            for (i = 0; i < 8; i = i + 1) begin
                @(posedge clk); rx_line = data[i];
            end
            @(posedge clk); rx_line = 1; // Stop bit
        end
    endtask

    initial begin
        $dumpfile("uart_system.vcd");
        $dumpvars(0, tb_UART_System);

        clk = 0; rst = 1; wr_en = 0; tx_start = 0;
        control_data = 8'b00000000;
        tx_data = 8'hA5; // Test byte
        rx_line = 1;

        $display("UART SYSTEM TEST START");

        #20 rst = 0;

        // Enable TX and RX
        control_data = 8'b00000011;
        wr_en = 1; #10; wr_en = 0;

        // Transmit
        #10 tx_start = 1;
        #10 tx_start = 0;

        // Simulate reception (matches transmitted byte)
        #200 send_serial(8'hA5);

        // Wait for RX to complete
        repeat(500) @(posedge clk);
        if (rx_done) begin
            $display("✅ Received Data: %h", rx_data);
        end else begin
            $display("❌ RX failed or timed out!");
        end

        #50 $finish;
    end
endmodule
