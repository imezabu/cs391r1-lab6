`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/08/2025 11:17:08 PM
// Design Name: 
// Module Name: cache_tb
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


module cache_tb();

// Parameters
    parameter INDEX_BITS = 8;
    parameter TAG_BITS = 24;
    parameter CLK_PERIOD = 10;
    
    // Clock and reset
    bit clk;
    bit rst;
    
    // CPU AXI signals
    bit cpu_awvalid;
    wire cpu_awready;
    bit [31:0] cpu_awaddr;
    bit [2:0] cpu_awprot;
    
    bit cpu_wvalid;
    wire cpu_wready;
    bit [31:0] cpu_wdata;
    bit [3:0] cpu_wstrb;
    
    wire cpu_bvalid;
    bit cpu_bready;
    
    bit cpu_arvalid;
    wire cpu_arready;
    bit [31:0] cpu_araddr;
    bit [2:0] cpu_arprot;
    
    wire cpu_rvalid;
    bit cpu_rready;
    wire [31:0] cpu_rdata;
    
    // BRAM AXI signals (Cache to BRAM)
    wire bram_awvalid;
    wire bram_awready;
    wire [19:0] bram_awaddr;
    wire [2:0] bram_awprot;
    
    wire bram_wvalid;
    wire bram_wready;
    wire [31:0] bram_wdata;
    wire [3:0] bram_wstrb;
    
    wire bram_bvalid;
    wire bram_bready;
    wire [1:0] bram_bresp;
    
    wire bram_arvalid;
    wire bram_arready;
    wire [19:0] bram_araddr;
    wire [2:0] bram_arprot;
    
    wire bram_rvalid;
    wire bram_rready;
    wire [31:0] bram_rdata;
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Cache instance
    cache #(
        .INDEX_BITS(INDEX_BITS),
        .TAG_BITS(TAG_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        // CPU side
        .cpu_awvalid(cpu_awvalid),
        .cpu_awready(cpu_awready),
        .cpu_awaddr(cpu_awaddr),
        .cpu_awprot(cpu_awprot),
        .cpu_wvalid(cpu_wvalid),
        .cpu_wready(cpu_wready),
        .cpu_wdata(cpu_wdata),
        .cpu_wstrb(cpu_wstrb),
        .cpu_bvalid(cpu_bvalid),
        .cpu_bready(cpu_bready),
        .cpu_arvalid(cpu_arvalid),
        .cpu_arready(cpu_arready),
        .cpu_araddr(cpu_araddr),
        .cpu_arprot(cpu_arprot),
        .cpu_rvalid(cpu_rvalid),
        .cpu_rready(cpu_rready),
        .cpu_rdata(cpu_rdata),
        // BRAM side
        .bram_awvalid(bram_awvalid),
        .bram_awready(bram_awready),
        .bram_awaddr(bram_awaddr),
        .bram_awprot(bram_awprot),
        .bram_wvalid(bram_wvalid),
        .bram_wready(bram_wready),
        .bram_wdata(bram_wdata),
        .bram_wstrb(bram_wstrb),
        .bram_bvalid(bram_bvalid),
        .bram_bready(bram_bready),
        .bram_arvalid(bram_arvalid),
        .bram_arready(bram_arready),
        .bram_araddr(bram_araddr),
        .bram_arprot(bram_arprot),
        .bram_rvalid(bram_rvalid),
        .bram_rready(bram_rready),
        .bram_rdata(bram_rdata)
    );
    
    // AXI BRAM Controller instance
    axi_bram_ctrl_0 my_bram(
        .s_axi_aclk(clk),
        .s_axi_aresetn(~rst),
        .s_axi_araddr(bram_araddr),
        .s_axi_arprot(bram_arprot),
        .s_axi_arready(bram_arready),
        .s_axi_arvalid(bram_arvalid),
        .s_axi_awaddr(bram_awaddr),
        .s_axi_awprot(bram_awprot),
        .s_axi_awready(bram_awready),
        .s_axi_awvalid(bram_awvalid),
        .s_axi_bready(bram_bready),
        .s_axi_bresp(bram_bresp),
        .s_axi_bvalid(bram_bvalid),
        .s_axi_rdata(bram_rdata),
        .s_axi_rready(bram_rready),
        .s_axi_rvalid(bram_rvalid),
        .s_axi_wdata(bram_wdata),
        .s_axi_wready(bram_wready),
        .s_axi_wstrb(bram_wstrb),
        .s_axi_wvalid(bram_wvalid)
    );

reg [31:0] addr;
reg [31:0] data;
initial begin
    cpu_awvalid=0;
    cpu_awaddr=0;
    cpu_wvalid=0;
    cpu_wdata=0;
    cpu_bready=0;
    cpu_arvalid=0;
    cpu_araddr=0;
    cpu_rready=0;
    
    //write to 0x000000_00 (8 bits index, the rest tag)
    rst=1; #100; rst=0;
    
    //write
   @(posedge clk);
   cpu_awvalid=1;
   cpu_awaddr={24'h000000, 8'h00}; //0x000000_00
   cpu_wvalid=1;
   cpu_wdata={32'hdeadbeef}; //write data
   wait(cpu_awready && cpu_wready);
   repeat (2) @(posedge clk);
   cpu_awvalid=0;
   cpu_wvalid=0;
   cpu_bready=1;
   wait(cpu_bvalid);
   repeat (2) @(posedge clk);   cpu_bready=0;
   //Inspect cache address to make sure it has correct data
   //if this causes an eviction, investigate evicted address in bram to make sure it worked
   
   
   //read of 0x000000_00
   @(posedge clk);
   cpu_arvalid=1;
   cpu_araddr={24'h000000, 8'h00}; //0x000000_00
   wait(cpu_arready);
   repeat (2) @(posedge clk);   cpu_rready=1;
   wait(cpu_rvalid);
   //inspect rdata to make sure its reading correct values
   //if you have a miss, make sure correct data is refilled
   // if this causes an eviction, investigate evicted address in bram to make sure it evicted right
   
   
   
end

endmodule