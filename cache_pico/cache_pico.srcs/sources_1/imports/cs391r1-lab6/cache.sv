`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2025 09:20:34 PM
// Design Name: 
// Module Name: cache
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


module cache #(
    parameter INDEX_BITS = 8,
    parameter TAG_BITS = (32-INDEX_BITS)
)(
    //basic
    input wire clk, input wire rst,
    
    //CPU AXI
    input wire cpu_awvalid,
    output reg cpu_awready, //We changed this (previously awread)
    input wire [31:0] cpu_awaddr,
    input wire [2:0] cpu_awprot, //ignore for now
    
    input wire cpu_wvalid,
    output reg cpu_wready,
    input wire [31:0]  cpu_wdata,
    input wire [3:0]  cpu_wstrb, //ignore for now
    
    output reg cpu_bvalid,
    input wire cpu_bready,
    
    input wire cpu_arvalid,
    output reg cpu_arready,
    input wire [31:0] cpu_araddr,
    input wire [2:0] cpu_arprot,// ignore for now
    
    output reg cpu_rvalid,
    input wire cpu_rready,
    output reg [31:0] cpu_rdata,
    
    //BRAM AXI
    
    output reg bram_awvalid,
    input wire bram_awready,
    output reg[31:0] bram_awaddr,
    output wire[2:0] bram_awprot, //hardcoded for now
    
    output reg bram_wvalid,
    input wire bram_wready,
    output reg[31:0] bram_wdata,
    output wire[3:0] bram_wstrb, //hardcoded for now
    
    input wire bram_bvalid,
    output reg bram_bready,
    
    output reg bram_arvalid,
    input wire bram_arready,
    output reg [31:0] bram_araddr,
    output wire [2:0] bram_arprot,// hardcoded for now
    
    input wire bram_rvalid,
    output reg bram_rready,
    input wire [31:0] bram_rdata
    );
    localparam NUM_LINES=1<<INDEX_BITS; //2^#of bits
    
    // states
    
    localparam IDLE=  3'b000;
    localparam READ_MEM= 3'b001;
    localparam OVERWRITE= 3'b010;
    localparam EVICT = 3'b011;
    localparam EVICT_ACK = 3'b100;
    localparam REFILL = 3'b101;
    localparam REFILL_ACK=3'b110;
    //TYPES
    localparam NONE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;
    
    reg [31:0] cache_data [0:NUM_LINES-1];
    reg cache_dirty[0:NUM_LINES-1];
    reg [TAG_BITS-1:0] cache_tag [0:NUM_LINES-1];
    reg cache_valid [0:NUM_LINES-1];
    
    reg [INDEX_BITS-1:0] index;
    reg [TAG_BITS-1:0] tag;
    
    reg [31:0] latched_addr; // current address
    reg [31:0] latched_data;
    reg [1:0] req_type; // bool for request type
    
    reg[2:0] state;
    //HARDCODED
    assign bram_awprot = 0;
    assign bram_arprot= 0;
    assign bram_wstrb = 4'b1111;
    integer i=0;
    
    always @(posedge clk) begin
        if (rst) begin
            // Reset control signals
            req_type <= NONE;
            cpu_awready <= 0;
            cpu_wready <= 0;
            cpu_bvalid <= 0;
            cpu_arready <= 0;
            cpu_rvalid <= 0;
            cpu_rdata <= 0;
            bram_awvalid <= 0;
            bram_wvalid <= 0;
            bram_bready <= 0;
            bram_arvalid <= 0;
            bram_rready <= 0;
            state <= IDLE;
            index <= 0;
            tag <= 0;
            bram_araddr <= 0;
            bram_awaddr <= 0;
            bram_wdata <= 0;
            latched_addr <= 0;
            latched_data <= 0;
            // Reset cache arrays - FIXED: integer declared inside block
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                cache_valid[i] <= 0;
                cache_dirty[i] <= 0;
            end
        end
        else begin
            
            case(state)
                IDLE: begin
                    cpu_arready <= 1;
                    cpu_awready <= 1;
                    cpu_wready  <= 1;
                    
                    //READS
                        if(cpu_arready && cpu_arvalid) begin //handshake
                            req_type<=READ;
                            latched_addr<=cpu_araddr;
                            tag<=cpu_araddr[31: INDEX_BITS]; //check range pleaseee
                            index<=cpu_araddr[INDEX_BITS-1:0];
                            
                            cpu_arready<=0; //stop all transactions
                            cpu_wready<=0;
                            cpu_awready<=0;
                            //HIT
                            if(cache_valid[cpu_awaddr[INDEX_BITS-1:0]] && cache_tag[cpu_awaddr[INDEX_BITS-1:0]]==cpu_araddr[31: INDEX_BITS]) begin
                                state<=READ_MEM; //maybe adjust
                                /*cache efficiency
                                cpu_rvalid<=1;
                                cpu_rdata<=cache_data[index];*/
                            end
                            //MISS
                            else begin
                                if(cache_valid[cpu_awaddr[INDEX_BITS-1:0]] && cache_dirty[cpu_awaddr[INDEX_BITS-1:0]]) begin //dirty
                                    state<=EVICT;
                                end else begin //non-dirty
                                    state<=REFILL;
                                end
                            end
                        
                        end
                    //WRITES
                    else if((cpu_awvalid && cpu_awready)&&(cpu_wready&&cpu_wvalid)) begin //AW and W handshake
                        req_type<=WRITE;
                        
                        
                            latched_addr<=cpu_awaddr;
                                tag<=cpu_awaddr[31: INDEX_BITS]; //check range pleaseee
                                index<=cpu_awaddr[INDEX_BITS-1:0];
                            latched_data<=cpu_wdata; //latch data
                            
                            cpu_arready<=0; //no new txns
                            cpu_wready<=0;
                            cpu_awready<=0;
                            //HIT
                            if(cache_valid[cpu_awaddr[INDEX_BITS-1:0]] && cache_tag[cpu_awaddr[INDEX_BITS-1:0]]==cpu_araddr[31: INDEX_BITS]) begin
                                state<=OVERWRITE;
                                /*efficiency? do this immediately on the clock?
                                cpu_bvalid<=1;
                                cache_data[index]<=latched_data;
                                cache_tag[index]<=tag;
                                cache_valid[index]<=1;
                                cache_dirty[index]<=1;*/
                            end
                            //MISS
                            else begin
                                if(cache_valid[cpu_awaddr[INDEX_BITS-1:0]] && cache_dirty[cpu_awaddr[INDEX_BITS-1:0]]) begin //dirty
                                    state<=EVICT;
                                end else begin //non-dirty
                                    state<=OVERWRITE; //maybe refill?
                                end
                            end
                        
                    end
                end
                READ_MEM: begin
                    cpu_rvalid<=1;
                    cpu_rdata<=cache_data[index];
                    if(cpu_rvalid && cpu_rready) begin 
                        cpu_rvalid<=0;
                        req_type<=NONE;
                        state<=IDLE;
                    end
                end
                OVERWRITE: begin
                    cpu_bvalid<=1;
                    cache_data[index]<=latched_data;
                    cache_tag[index]<=tag;
                    cache_valid[index]<=1;
                    cache_dirty[index]<=1;
                    if(cpu_bvalid && cpu_bready) begin
                        cpu_bvalid<=0;
                        req_type<=NONE;
                        state<=IDLE;
                    end
                end
                
                REFILL: begin
                    bram_arvalid<=1;
                    bram_araddr<=latched_addr;
                    if(bram_arvalid && bram_arready) begin
                        bram_arvalid<=0;
                        state<=REFILL_ACK;
                    end
                end
                REFILL_ACK: begin
                    bram_rready<=1;
                    if(bram_rready && bram_rvalid) begin
                        bram_rready<=0;
                        cache_data[index]<=bram_rdata;
                        cache_valid[index]<=1;
                        cache_dirty[index]<=0;
                        cache_tag[index]<=tag;
                        state<=READ_MEM; //if we implement clean write refill then we need logic here to change this depending on txn type
                    end
                end
                EVICT: begin
                    bram_awaddr<={cache_tag[index], index};
                    bram_awvalid<=1;
                    bram_wdata<=cache_data[index];
                    bram_wvalid<=1;
                    if((bram_awvalid&&bram_awready)&&(bram_wready&&bram_wvalid)) begin
                        bram_awvalid<=0;
                        bram_wvalid<=0;
                        bram_bready<=1;
                        cache_valid[index]<=0; //safety?
                        state<=EVICT_ACK;
                    end
                end
                EVICT_ACK: begin
                    if(bram_bready&&bram_bvalid) begin
                        bram_bready<=0;
                        if(req_type==READ) begin
                            state<=REFILL;
                        end else begin
                            state<=OVERWRITE;
                        end
                    end
                end
            endcase
        
        
        
        end
    end
    
endmodule
/*if (cpu_arvalid) begin
            we <= 0; // write enable is turned off
            latched_addr <= cpu_araddr;
            cache_tag <= cpu_araddr[:]; // could need to change this to diff tag name
            index <= cpu_araddr[:];
            if (cpu_valid[index] && cache_tag[index] == tag) begin
                state <= READ_HIT; 
                cpu_rdata = cache_data[index];
                cpu_rvalid <= 1; 
            end 
            else begin
                if (cache_dirty[index]) begin
                    state <= EVICT;
                end else begin
                    state <= READ_MISS; 
                end
            end 
        end */
   