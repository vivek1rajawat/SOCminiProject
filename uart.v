`timescale 1ns/1ps

// ===== Control Register =====
module ControlRegister (
    input clk,
    input rst,
    input wr_en,
    input [7:0] data_in,
    output reg tx_en,
    output reg rx_en,
    output reg reset
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_en <= 0;
        rx_en <= 0;
        reset <= 0;
    end else if (wr_en) begin
        tx_en <= data_in[0];
        rx_en <= data_in[1];
        reset <= data_in[2];
    end
end
endmodule

// ===== UART Transmitter =====
module UART_TX (
    input clk,
    input tx_en,
    input [7:0] tx_data,
    input tx_start,
    output reg tx_line,
    output reg tx_done
);
    reg [3:0] state;
    reg [2:0] bit_index;
    reg [9:0] shift_reg;

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, DONE = 4;

    initial begin
        tx_line = 1;
        tx_done = 0;
    end

    always @(posedge clk) begin
        if (!tx_en) begin
            state <= IDLE;
            tx_line <= 1;
            tx_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_done <= 0;
                    if (tx_start) begin
                        shift_reg <= {1'b1, tx_data, 1'b0}; // stop + data + start
                        bit_index <= 0;
                        state <= START;
                    end
                end
                START: begin
                    tx_line <= 0;
                    state <= DATA;
                end
                DATA: begin
                    tx_line <= shift_reg[bit_index];
                    bit_index <= bit_index + 1;
                    if (bit_index == 7)
                        state <= STOP;
                end
                STOP: begin
                    tx_line <= 1;
                    state <= DONE;
                end
                DONE: begin
                    tx_done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

// ===== UART Receiver =====
module UART_RX (
    input clk,
    input rx_en,
    input rx_line,
    output reg [7:0] rx_data,
    output reg rx_done
);
    reg [3:0] state;
    reg [3:0] bit_index;
    reg [7:0] shift_reg;

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, DONE = 4;

    initial begin
        rx_data = 0;
        rx_done = 0;
    end

    always @(posedge clk) begin
        if (!rx_en) begin
            state <= IDLE;
            rx_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rx_done <= 0;
                    if (!rx_line)
                        state <= START;
                end
                START: begin
                    bit_index <= 0;
                    state <= DATA;
                end
                DATA: begin
                    shift_reg[bit_index] <= rx_line;
                    bit_index <= bit_index + 1;
                    if (bit_index == 7)
                        state <= STOP;
                end
                STOP: begin
                    if (rx_line == 1) begin
                        rx_data <= shift_reg;
                        state <= DONE;
                    end else
                        state <= IDLE;
                end
                DONE: begin
                    rx_done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

// ===== UART Top-Level System =====
module UART_System (
    input clk,
    input rst,
    input wr_en,
    input [7:0] control_data,
    input tx_start,
    input [7:0] tx_data,
    input rx_line,
    output tx_line,
    output [7:0] rx_data,
    output tx_done,
    output rx_done
);
    wire tx_en, rx_en, reset;

    ControlRegister ctrl (
        .clk(clk), .rst(rst), .wr_en(wr_en), .data_in(control_data),
        .tx_en(tx_en), .rx_en(rx_en), .reset(reset)
    );

    UART_TX tx (
        .clk(clk), .tx_en(tx_en), .tx_data(tx_data), .tx_start(tx_start),
        .tx_line(tx_line), .tx_done(tx_done)
    );

    UART_RX rx (
        .clk(clk), .rx_en(rx_en), .rx_line(rx_line),
        .rx_data(rx_data), .rx_done(rx_done)
    );
endmodule
