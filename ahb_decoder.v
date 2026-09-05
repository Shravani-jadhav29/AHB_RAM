`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2026 07:28:50 PM
// Design Name: 
// Module Name: ahb_decoder
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


module ahb_decoder(


    //================================================
    // FROM MASTER
    //================================================
    input wire [31:0] HADDR_M,
    input wire [31:0] HWDATA_M,
    input wire         HWRITE_M,
    input wire [1:0]  HTRANS_M,
    input wire [2:0]  HSIZE_M,
    input wire [2:0]  HBURST_M,

    //================================================
    // FROM RAM SLAVE
    //================================================
    input wire [31:0] HRDATA_RAM,
    input wire         HREADY_RAM,

    //================================================
    // FROM BRIDGE SLAVE
    //================================================
    input wire [31:0] HRDATA_BRIDGE,
    input wire         HREADY_BRIDGE,

    //================================================
    // TO RAM SLAVE
    //================================================
    output reg [31:0] HADDR_RAM,
    output reg [31:0] HWDATA_RAM,
    output reg          HWRITE_RAM,
    output reg [1:0]  HTRANS_RAM,
    output reg [2:0]  HSIZE_RAM,
    output reg [2:0]  HBURST_RAM,

    //================================================
    // TO BRIDGE SLAVE
    //================================================
    output reg [31:0] HADDR_BRIDGE,
    output reg [31:0] HWDATA_BRIDGE,
    output reg          HWRITE_BRIDGE,
    output reg [1:0]  HTRANS_BRIDGE,
    output reg [2:0]  HSIZE_BRIDGE,
    output reg [2:0]  HBURST_BRIDGE,
    output wire         HSEL_BRIDGE,     // also used as APB bridge's "hselapb"

    //================================================
    // BACK TO MASTER
    //================================================
    output reg [31:0] HRDATA_M,
    output reg          HREADY_M
);

    //================================================
    // ADDRESS DECODE (combinational, based on current
    // address phase from the master)
    //================================================

    wire select_ram;
    wire select_bridge;

    assign select_ram    = (HTRANS_M != 2'b00) && (HADDR_M <  32'h00000020);
    assign select_bridge = (HTRANS_M != 2'b00) && (HADDR_M >= 32'h00000020);

    assign HSEL_BRIDGE = select_bridge;

    //================================================
    // DEMUX: MASTER -> SELECTED SLAVE
    //================================================

    always @(*)
    begin
        // Defaults: both slaves de-selected / idle
        HADDR_RAM  = 32'd0;
        HWDATA_RAM = 32'd0;
        HWRITE_RAM = 1'b0;
        HTRANS_RAM = 2'b00;
        HSIZE_RAM  = 3'b010;
        HBURST_RAM = 3'b000;

        HADDR_BRIDGE  = 32'd0;
        HWDATA_BRIDGE = 32'd0;
        HWRITE_BRIDGE = 1'b0;
        HTRANS_BRIDGE = 2'b00;
        HSIZE_BRIDGE  = 3'b010;
        HBURST_BRIDGE = 3'b000;

        if(select_ram)
        begin
            HADDR_RAM  = HADDR_M;
            HWDATA_RAM = HWDATA_M;
            HWRITE_RAM = HWRITE_M;
            HTRANS_RAM = HTRANS_M;
            HSIZE_RAM  = HSIZE_M;
            HBURST_RAM = HBURST_M;
        end
        else if(select_bridge)
        begin
            HADDR_BRIDGE  = HADDR_M;
            HWDATA_BRIDGE = HWDATA_M;
            HWRITE_BRIDGE = HWRITE_M;
            HTRANS_BRIDGE = HTRANS_M;
            HSIZE_BRIDGE  = HSIZE_M;
            HBURST_BRIDGE = HBURST_M;
        end
    end

    //================================================
    // MUX: SELECTED SLAVE -> MASTER
    //================================================

    always @(*)
    begin
        if(select_ram)
        begin
            HRDATA_M = HRDATA_RAM;
            HREADY_M = HREADY_RAM;
        end
        else if(select_bridge)
        begin
            HRDATA_M = HRDATA_BRIDGE;
            HREADY_M = HREADY_BRIDGE;
        end
        else
        begin
            HRDATA_M = 32'd0;
            HREADY_M = 1'b1;      // no slave selected -> don't stall master
        end
    end

endmodule
