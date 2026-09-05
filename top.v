`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2026 07:35:57 PM
// Design Name: 
// Module Name: Nexys_a7
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


module Nexys_a7(

  

    input        CLK100MHZ,
    input        CPU_RESETN,

    input        BTNU,
    input        BTNC,

    input  [15:0] SW,

    output [15:0] LED,
    output [6:0]  SEG,
    output [3:0]  AN,
    output        DP
);

    //================================================
    // CLOCK / RESET
    //================================================

    wire HCLK;
    wire HRESETn;

    assign HCLK    = CLK100MHZ;
    assign HRESETn = CPU_RESETN;

    //================================================
    // BUTTON DEBOUNCE
    //================================================

    wire btn_write_db;
    wire btn_read_db;

    debounce debounce_write (
        .clk    (HCLK),
        .rst    (~HRESETn),
        .btn    (BTNC),
        .btn_db (btn_write_db)
    );

    debounce debounce_read (
        .clk    (HCLK),
        .rst    (~HRESETn),
        .btn    (BTNU),
        .btn_db (btn_read_db)
    );

    //================================================
    // EDGE DETECTOR
    //================================================

    wire write_pulse;
    wire read_pulse;

    edge_detector edge_write (
        .clk       (HCLK),
        .rst       (~HRESETn),
        .signal_in (btn_write_db),
        .pulse     (write_pulse)
    );

    edge_detector edge_read (
        .clk       (HCLK),
        .rst       (~HRESETn),
        .signal_in (btn_read_db),
        .pulse     (read_pulse)
    );

    //================================================
    // USER INPUT -> MASTER REQUEST
    //================================================

    wire        start;
    wire        write_enable;

    wire [31:0] address;
    wire [31:0] write_data;

    assign start        = write_pulse | read_pulse;
    assign write_enable = write_pulse;

    assign address    = {24'h000000, SW[7:0]};   // SW[7:0]  = address
    assign write_data = {24'h000000, SW[15:8]};  // SW[15:8] = write data

    //================================================
    // AHB MASTER <-> DECODER SIGNALS
    //================================================

    wire [31:0] HADDR_M;
    wire [31:0] HWDATA_M;
    wire        HWRITE_M;
    wire [1:0]  HTRANS_M;
    wire [2:0]  HSIZE_M;
    wire [2:0]  HBURST_M;

    wire [31:0] HRDATA_M;
    wire        HREADY_M;
    wire        HRESP_M;

    wire [31:0] read_data;
    wire        done;

    // Neither slave in this system currently reports a bus error,
    // so tie HRESP to OKAY. (Extend this if a slave ever needs to
    // signal HRESP=ERROR.)
    assign HRESP_M = 1'b0;

    //================================================
    // AHB-LITE MASTER
    //================================================

    AHB_master master (

        .HCLK         (HCLK),
        .HRESETn      (HRESETn),

        .start        (start),
        .write_enable (write_enable),

        .address      (address),
        .write_data   (write_data),

        .HRDATA       (HRDATA_M),
        .HREADY       (HREADY_M),
        .HRESP        (HRESP_M),

        .HADDR        (HADDR_M),
        .HWDATA       (HWDATA_M),
        .HWRITE       (HWRITE_M),
        .HTRANS       (HTRANS_M),
        .HSIZE        (HSIZE_M),
        .HBURST       (HBURST_M),

        .read_data    (read_data),
        .done         (done)
    );

    //================================================
    // DECODER -> RAM
    //================================================

    wire [31:0] HADDR_RAM;
    wire [31:0] HWDATA_RAM;
    wire        HWRITE_RAM;
    wire [1:0]  HTRANS_RAM;
    wire [2:0]  HSIZE_RAM;
    wire [2:0]  HBURST_RAM;

    wire [31:0] HRDATA_RAM;
    wire        HREADY_RAM;

    //================================================
    // DECODER -> BRIDGE
    //================================================

    wire [31:0] HADDR_BRIDGE;
    wire [31:0] HWDATA_BRIDGE;
    wire        HWRITE_BRIDGE;
    wire [1:0]  HTRANS_BRIDGE;
    wire [2:0]  HSIZE_BRIDGE;
    wire [2:0]  HBURST_BRIDGE;
    wire        HSEL_BRIDGE;

    wire [31:0] HRDATA_BRIDGE;
    wire        HREADY_BRIDGE;

    //================================================
    // AHB DECODER (address-based select, single master)
    //================================================

    ahb_decoder decoder (

        .HADDR_M        (HADDR_M),
        .HWDATA_M       (HWDATA_M),
        .HWRITE_M       (HWRITE_M),
        .HTRANS_M       (HTRANS_M),
        .HSIZE_M        (HSIZE_M),
        .HBURST_M       (HBURST_M),

        .HRDATA_RAM     (HRDATA_RAM),
        .HREADY_RAM     (HREADY_RAM),

        .HRDATA_BRIDGE  (HRDATA_BRIDGE),
        .HREADY_BRIDGE  (HREADY_BRIDGE),

        .HADDR_RAM      (HADDR_RAM),
        .HWDATA_RAM     (HWDATA_RAM),
        .HWRITE_RAM     (HWRITE_RAM),
        .HTRANS_RAM     (HTRANS_RAM),
        .HSIZE_RAM      (HSIZE_RAM),
        .HBURST_RAM     (HBURST_RAM),

        .HADDR_BRIDGE   (HADDR_BRIDGE),
        .HWDATA_BRIDGE  (HWDATA_BRIDGE),
        .HWRITE_BRIDGE  (HWRITE_BRIDGE),
        .HTRANS_BRIDGE  (HTRANS_BRIDGE),
        .HSIZE_BRIDGE   (HSIZE_BRIDGE),
        .HBURST_BRIDGE  (HBURST_BRIDGE),
        .HSEL_BRIDGE    (HSEL_BRIDGE),

        .HRDATA_M       (HRDATA_M),
        .HREADY_M       (HREADY_M)
    );

    //================================================
    // AHB RAM SLAVE
    //================================================

    ahb_ram_slave RAM_SLAVE (

        .HCLK       (HCLK),
        .HRESETn    (HRESETn),

        .HADDR      (HADDR_RAM),
        .HWDATA     (HWDATA_RAM),
        .HWRITE     (HWRITE_RAM),
        .HTRANS     (HTRANS_RAM),
        .HSIZE      (HSIZE_RAM),
        .HBURST     (HBURST_RAM),

        .HRDATA     (HRDATA_RAM),
        .HREADY     (HREADY_RAM)
    );

    //================================================
    // APB SIGNALS
    //================================================

    wire        PSEL;
    wire        PENABLE;
    wire        PWRITE;

    wire [31:0] PADDR;
    wire [31:0] PWDATA;
    wire [31:0] PRDATA;

    //================================================
    // AHB -> APB BRIDGE
    //================================================

     bridge (

        .hclk      (HCLK),
        .hresetn   (HRESETn),

        .hselapb   (HSEL_BRIDGE),
        .hwrite    (HWRITE_BRIDGE),
        .htrans    (HTRANS_BRIDGE),
        .haddr     (HADDR_BRIDGE),
        .hwdata    (HWDATA_BRIDGE),

        .prdata    (PRDATA),

        .psel      (PSEL),
        .penable   (PENABLE),
        .pwrite    (PWRITE),
        .paddr     (PADDR),
        .pwdata    (PWDATA),

        .hresp     (),               // no slave error reporting yet
        .hready    (HREADY_BRIDGE),
        .hrdata    (HRDATA_BRIDGE)
    );

    //================================================
    // APB DECODER
    //================================================

    wire uart_sel;
    wire gpio_sel;
    wire fifo_sel;
    wire pwm_sel;

    decoder apb_dec (

        .psel      (PSEL),
        .paddr     (PADDR[7:0]),

        .uart_sel  (uart_sel),
        .gpio_sel  (gpio_sel),
        .fifo_sel  (fifo_sel),
        .pwm_sel   (pwm_sel)
    );

    //================================================
    // FIFO SIGNALS
    //================================================

    wire       fifo_wr_en;
    wire       fifo_rd_en;

    wire [7:0] fifo_data_in;
    wire [7:0] fifo_data_out;

    wire       fifo_full;
    wire       fifo_empty;

    //================================================
    // APB FIFO SLAVE
    //================================================

    apb_slave fifo_apb (

        .clk       (HCLK),
        .rst       (~HRESETn),

        .psel      (fifo_sel),
        .penable   (PENABLE),
        .pwrite    (PWRITE),

        .pwdata    (PWDATA),
        .prdata    (PRDATA),

        .pready    (),
        .pslverr   (),

        .wr_en     (fifo_wr_en),
        .rd_en     (fifo_rd_en),

        .data_in   (fifo_data_in),
        .data_out  (fifo_data_out),

        .full      (fifo_full),
        .empty     (fifo_empty)
    );

    //================================================
    // FIFO
    //================================================

    fifo fifo_inst (

        .clk       (HCLK),
        .rst       (~HRESETn),

        .wr_en     (fifo_wr_en),
        .rd_en     (fifo_rd_en),

        .data_in   (fifo_data_in),
        .data_out  (fifo_data_out),

        .full      (fifo_full),
        .empty     (fifo_empty)
    );

    //================================================
    // 7-SEGMENT DISPLAY (shows last read data)
    //================================================

    board DISP (
        .clk  (HCLK),
        .data (read_data[7:0]),
        .an   (AN),
        .seg  (SEG)
    );

    assign DP = 1'b1;

    //================================================
    // LED OUTPUT
    //================================================

    assign LED[7:0]  = read_data[7:0];
    assign LED[8]    = HRESP_M;
    assign LED[9]    = HREADY_M;
    assign LED[10]   = fifo_wr_en;
    assign LED[11]   = fifo_rd_en;
    assign LED[12]   = PSEL;
    assign LED[13]   = PENABLE;
    assign LED[14]   = PWRITE;
    assign LED[15]   = ~fifo_empty;

endmodule
