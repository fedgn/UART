`timescale 1ns / 1ps

module UART_RX
#(
    parameter CLK_FREQ  = 100000000,
    parameter BAUD_RATE = 115200
)
(
    input           clk,
    input           uart_i,
    
    output reg [7:0]uart_o,
    output reg      rx_done
    );
    
    reg [7:0]   rx_data       = 8'h00;
    reg [2:0]   data_cntr     = 3'b000;
    reg         parity        = 1'b0;
    
    reg         uart_clk      = 1'b0;
    integer     uart_clk_cntr = 0;
    
    localparam  cntr_lim    = CLK_FREQ/BAUD_RATE;
    
    localparam  IDLE        = 3'b000,
                START       = 3'b001,
                DATA        = 3'b010,
                PARITY      = 3'b011,
                STOP        = 3'b100;
    
    reg [2:0] state = IDLE;
    
    always @ (posedge uart_clk) begin
        if (uart_clk == 1'b1) begin
            case  (state)
                IDLE: begin
                    data_cntr           <= 3'b000;
                    parity              <= 1'b0;
                    if (uart_i == 1'b0) begin
                        state           <= START;
                        rx_data         <= 8'h00;
                        rx_done         <= 1'b0;
                    end
                end
                
                START: begin
                    state           <= DATA;
                    rx_data[6:0]    <= rx_data[7:1];
                    rx_data[7]      <= uart_i;
                    data_cntr       <= data_cntr + 1'b1;
                end
                
                DATA: begin
                    if (data_cntr == 3'b111) begin
                        state           <= PARITY;
                        rx_data[6:0]    <= rx_data[7:1];
                        rx_data[7]      <= uart_i;
                        parity          <= uart_i ^ rx_data[1] ^ rx_data[2] ^ rx_data[3] ^ rx_data[4] ^ rx_data[5] ^ rx_data[6] ^ rx_data[7];
                    end
                    else begin
                        state           <= DATA;
                        rx_data[6:0]    <= rx_data[7:1];
                        rx_data[7]      <= uart_i;
                        data_cntr       <= data_cntr + 1'b1;
                    end
                end
                
                PARITY: begin
                    if (parity == uart_i) begin
                        state           <= STOP;
                    end
                    else begin
                        state           <= IDLE;
                    end
                end
                
                STOP: begin
                    state               <= IDLE;
                    if (uart_i == 1'b1) begin
                        rx_done             <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    always @ (posedge clk) begin
        if (clk == 1'b1) begin
            if (uart_clk_cntr == (cntr_lim/2) - 1) begin
                uart_clk        <= 1'b1;
                uart_clk_cntr   <= uart_clk_cntr + 1;
            end
            else if (uart_clk_cntr == cntr_lim - 1) begin
                uart_clk        <= 1'b0;
                uart_clk_cntr   <= 0;
            end
            else begin
                uart_clk_cntr   <= uart_clk_cntr + 1;
            end
        end
    end
    
    always @ (*) begin
        if(rx_done)
            uart_o = rx_data;
    end
endmodule
