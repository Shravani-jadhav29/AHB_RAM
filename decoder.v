`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2026 07:32:23 PM
// Design Name: 
// Module Name: decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decoder(

  
    input  wire        psel,
    input  wire [7:0]  paddr,

    output reg          uart_sel,
    output reg          gpio_sel,
    output reg          fifo_sel,
    output reg          pwm_sel
);

    always @(*) begin
        uart_sel = 1'b0;
        gpio_sel = 1'b0;
        fifo_sel = 1'b0;
        pwm_sel  = 1'b0;

        if (psel) begin
            case (paddr)
                8'h05:   uart_sel = 1'b1;
                8'h10:   gpio_sel = 1'b1;
                8'h20:   fifo_sel = 1'b1;
                8'h30:   pwm_sel  = 1'b1;
                default: ;
            endcase
        end
    end

endmodule
