`timescale 1ns / 1ps
module read_sink (
input clk, readBufClk,
input sinkWE,
input [9:0] sinkAddr,
input [15:0] DQ,
input [9:0] readBufAddr,
output reg [15:0] readBufData 
);

     parameter RAM_WIDTH     = 16;
    parameter RAM_ADDR_BITS = 10;

    /*read buffer*/
    reg [RAM_WIDTH-1:0] readBuffer [(2**RAM_ADDR_BITS)-1:0];

    initial begin : init
      integer i;
      for (i = 0; i < (2**RAM_ADDR_BITS); i = i + 1) begin
        readBuffer[i] = 0;
      end
    end

    always @(posedge clk)
        if (sinkWE)
            readBuffer[sinkAddr] <= DQ;

    always @(posedge readBufClk)
        readBufData <= readBuffer[readBufAddr];

endmodule
