`timescale 1ns/1ps
module tb_UART_System;

    reg clk, rst, wr_en, tx_start;
    reg [7:0] control_data, tx_data;
    wire tx_line, tx_done, rx_done;
    wire [7:0] rx_data;

    // ✅ Loopback wire
    wire rx_line;
    assign rx_line = tx_line;  // LOOPBACK CONNECTION

    // Instantiate Top UART System
    UART_System uut (
        .clk(clk), .rst(rst), .wr_en(wr_en), .control_data(control_data),
        .tx_start(tx_start), .tx_data(tx_data),
        .rx_line(rx_line),
        .tx_line(tx_line), .rx_data(rx_data),
        .tx_done(tx_done), .rx_done(rx_done)
    );

    // Clock generator
    always #5 clk = ~clk;

    initial begin
        $dumpfile("uart_system.vcd");
        $dumpvars(0, tb_UART_System);

        clk = 0; rst = 1; wr_en = 0; tx_start = 0;
        control_data = 8'b00000000;
        tx_data = 8'hA5;

        $display("UART SYSTEM LOOPBACK TEST START");

        #20 rst = 0;

        // Enable TX and RX
        control_data = 8'b00000011;
        wr_en = 1; #10; wr_en = 0;

        // Transmit A5
        #10 tx_start = 1;
        #10 tx_start = 0;

        // Wait for RX done
        repeat (500) @(posedge clk);

        if (rx_done)
            $display("✅ RX Received Data: %h", rx_data);
        else
            $display("❌ ERROR: RX failed or timed out");

        #50 $finish;
    end
endmodule
