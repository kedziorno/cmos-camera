`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:17:28 03/15/2026
// Design Name:   CellRAMBurstController
// Module Name:   /home/user/_WORKSPACE_/cmos-camera/cmos-camera/tb_RAMcont.v
// Project Name:  cmos-camera
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: CellRAMBurstController
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_RAMcont;

	// Inputs
	reg clk = 0;
	reg write;
	reg [15:0] data;
	reg [15:0] id;
	reg [10:0] writeBufAddr;
	wire [7:0] cam_data70;
	reg writeBufClk = 0;
	reg writeBufWE;
	reg [9:0] readBufAddr;
	reg readBufClk;
	reg O_WAIT;

	// Outputs
	wire busy;
	wire [15:0] readBufData;
	wire LB;
	wire UB;
	wire OE;
	wire WE;
	wire ADV;
	wire CE;
	wire CRE;
	wire RAM_CLK;
	wire [22:0] A;

	// Bidirs
	wire [15:0] DQ;

  reg clkvga = 0;
  
  always clkvga = #20 ~clkvga;
  always clk = #5 ~clk;
  always writeBufClk = #20.833333 ~writeBufClk;
  wire cam_pclk;
  wire cam_hs;
  wire cam_vs;
  	 wire [10:0]camAddress;
   
  camera cam_uut (
.camera_io_scl(), 
.camera_io_sda(),
.camera_o_vs(cam_vs),
.camera_o_hs(cam_hs),
.camera_o_pclk(cam_pclk),
.camera_i_xclk(writeBufClk),
.camera_o_d(cam_data70),
.camera_i_rst(),
.camera_i_pwdn()
);

	 VGA vga_cont(.clk25MHz(clkvga), .VGAData(readBufData), .VGAAddress(readBufAddr), .VGAClk(VGAClk), .vga(vga),
	              .hsync(hsync), .vsync(vsync), .frameInterrupt(frameInterrupt), .dataInterrupt(dataInterrupt));
                
cam_Controller camCont(.pclk(cam_pclk), .vsync(cam_vs), .href(cam_hs), .address(camAddress),
	                        .dataInterrupt(camDataInt), .frameInterrupt(camFrameInt));
                          
	// Instantiate the Unit Under Test (UUT)
	CellRAMBurstController uut (
		.busy(busy), 
		.clk(clk), 
		.write(write), 
		.data(data), 
		.id(id), 
		.writeBufAddr(camAddress), 
		.writeBufData(cam_data70), 
		.writeBufClk(cam_pclk), 
		.writeBufWE(cam_hs), 
		.readBufAddr(readBufAddr), 
		.readBufData(readBufData), 
		.readBufClk(readBufClk), 
		.LB(LB), 
		.UB(UB), 
		.OE(OE), 
		.WE(WE), 
		.ADV(ADV), 
		.CE(CE), 
		.CRE(CRE), 
		.RAM_CLK(RAM_CLK), 
		.O_WAIT(O_WAIT), 
		.A(A), 
		.DQ(DQ)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		write = 0;
		data = 0;
		id = 0;
		writeBufAddr = 0;
		//cam_data70 = 0;
		writeBufClk = 0;
		writeBufWE = 0;
		readBufAddr = 0;
		readBufClk = 0;
		O_WAIT = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

