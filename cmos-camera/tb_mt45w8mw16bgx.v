// Testbench for CellularRAM

// DO NOT CHANGE THE TIMESCALE
// MAKE SURE YOUR SIMULATOR USE "PS" RESOLUTION
`timescale 1ns / 100ps

module tb_mt45w8mw16bgx;

`define CR15
`define sg701
`define x16

`include "micron_mem_parameters.v"

    // Ports register
    reg  [data_bits - 1 : 0] dq_out;
    tri1                     owait_verilog;
    reg                      clk;
    reg  [addr_bits - 1 : 0] addr;
    reg                      ce_n;
    reg                      we_n;
    reg                      adv_n;
    reg                      oe_n;
    reg                      cre;
    reg                      lb_n;
    reg                      ub_n;

    reg              [2 : 0] latency_counter;

    wire [data_bits - 1 : 0] dq_verilog = dq_out;
    wire             [1 : 0] b_n = {ub_n, lb_n};


    mt45w8mw16bgx uut_mt45w8mw16bgx (
       .Addr(addr), 
       .Adv_n(adv_n), 
       .Ce_n(ce_n), 
       .Clk(clk), 
       .Cre(cre), 
       .Dq(dq_verilog), 
       .Lb_n(lb_n), 
       .Oe_n(oe_n), 
       .oWait(owait_verilog),
       .Ub_n(ub_n),
       .We_n(we_n) 
       );

    initial begin
        dq_out   = 16'bz;
        addr = 23'b0;
        clk  =  1'b0;
        ce_n =  1'b1;
        we_n =  1'b1;
        oe_n =  1'b1;
        lb_n =  1'b1;
        ub_n =  1'b1;
        cre = 1'b0;
        adv_n = 1'b1;
        latency_counter = 3'b011;   //Default register value
    end
 
    task nop;
        begin
            addr  = 'bz;
            dq_out= 'bz;
            clk   = 1'b0;
            ce_n  = 1'b0;
            cre   = 1'b0;
            #tRC;
        end
    endtask


    /**************************************************************************
    *
    *  Figure 20: Initialization Period
    *
    **************************************************************************/
    
    task initialization_period;
        begin
            $display ($time," TB:INIT");
            addr  = 'bz;
            dq_out= 'bz;
            clk   = 1'b0;
            ce_n  = 1'b1;
            adv_n = 1'b1;
            we_n  = 1'b1;
            lb_n  = 1'b1;
            ub_n  = 1'b1;
            cre   = 1'b0;
            oe_n  = 1'b1;
            #(tPU);
        end
    endtask

    /**************************************************************************
    *
    *  Figure 12: Asynchronous Configuration Register WRITE
    *
    **************************************************************************/
    
    task async_config_write;
        input [addr_bits - 1 : 0] config_data;
    begin
        $display ($time," TB:ASYNC CONFIG WRITE");
        fork
            begin : clk_blk 
                clk <= 1'b0; 
            end
            begin : cre_blk 
                cre <= 1'b1; 
            end
            begin : addr_blk 
                addr <= 'bz;
                addr <= #(tVPH + tVP - tAVS) config_data;
                addr <= #(tVPH + tVP + tAVH) 'bz;
            end
            begin : adv_blk

                adv_n <= 1'b1; 
                adv_n <= #(tVPH) 1'b0;
                adv_n <= #(tVPH + tVP) 1'b1;
            end
            begin : ce_blk
                ce_n <= 1'b1;
                ce_n <= #(tVPH) 1'b0; 
                ce_n <= #(tVPH + tCW) 1'b1;
            end
            begin : lb_blk
                lb_n <= 1'b1;
                lb_n <= #(tVPH) 1'b0; 
                lb_n <= #(tVPH + tBW + tWPH) 1'b1;
            end
            begin : ub_blk
                ub_n <= 1'b1;
                ub_n <= #(tVPH) 1'b0; 
                ub_n <= #(tVPH + tBW + tWPH) 1'b1;
            end
            begin : oe_blk
                oe_n <= 1'b1;
            end
            begin : we_blk 
                we_n <= 1'b1;
                we_n <= #(tCW-tWP) 1'b0;  
                 //we_n <= #(tVPH) 1'b0;  // divergent xxx orig
                we_n <= #(tCW + 30) 1'b1;
                 //we_n <= #(tVPH + tBW) 1'b1;  // divergent xxx orig
            end
            begin : dq_blk 
                dq_out <= {data_bits{1'bz}}; 
            end
            #(tVPH + tCW + tWC);
            // Must add a read array operation 
        join
    end
    endtask

    /**************************************************************************
    *
    *  Figure 21: Asynchronous config READ
    *
    **************************************************************************/

    task async_config_read;
        input [1 : 0] which_register; // 00=RCR, 10=BCR, 01=DIDR
    begin
        $display ($time," TB:ASYNC CONFIG READ");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
                cre <= #(tVPH) 1'b1;
                cre <= #(tVPH + tAVS + tAVH) 1'b0;
            end
            begin : addr_blk 
                addr <= #10 'b0;
                addr[19:18] <= #10 which_register; 
                addr <= #(tAVS+tAVH+10) 'bz; 
            end
            begin : adv_blk
                adv_n <= 1'b1;
                adv_n <= #(tVPH) 1'b0;
                adv_n <= #(tVPH + tVP) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(tVPH) 1'b0;
                ce_n <= #(tVPH + tRC) 1'b1;
                ce_n <= #(tVPH + tRC + 5) 1'b0;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(tCBPH) 1'b0;
                lb_n <= #(tCBPH + tRC) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(tCBPH) 1'b0;
                ub_n <= #(tCBPH + tRC) 1'b1;
            end
            begin : oe_blk 
                oe_n <= 1'b1; 
                oe_n <= #(tVPH + tAADV - tOE) 1'b0; 
                oe_n <= #(tVPH + tAADV + 5) 1'b1; // The 5 is arbitrary
                //oe_n <= #(tVPH + tAADV + 5 + tOHZ) 1'b0; 
            end
            begin : we_blk 
                we_n <= 1'b1;
            end
            begin : dq_blk
                dq_out <= {data_bits{1'bz}};
            end
            #(tCBPH + tRC + tCBPH);
        join
    end
    endtask


    /**************************************************************************
    *
    *  Figure 21: Asynchronous READ
    *
    **************************************************************************/

    task asynchronous_read_cycle;
        input [addr_bits - 1 : 0] rd_addr;
    begin
        $display ($time," TB:ASYNC READ CYCLE");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
            end
            begin : addr_blk 
                addr <= 'bz;
                addr <= #(5) rd_addr; 
                addr <= #(5 + tCBPH + tRC) 'bz;
            end
            begin : adv_blk
                adv_n <= 1'b0;
                //adv_n <= #(5 + tCBPH) 1'b0;
                //adv_n <= #(5 + tCBPH + tRC) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(5) 1'b0;
                ce_n <= #(5 + tCBPH + tRC) 1'b1;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(5 + tCBPH) 1'b0;
                lb_n <= #(5 + tCBPH + tRC) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(5 + tCBPH) 1'b0;
                ub_n <= #(5 + tCBPH + tRC) 1'b1;
            end
            begin : oe_blk 
                oe_n <= 1'b1; 
                oe_n <= #(5 + tCO-tOE) 1'b0; 
                oe_n <= 1'b1; 
            end
            begin : we_blk 
                we_n <= 1'b1;
            end
            begin : dq_blk
                dq_out <= 'bz;
            end
            #(5 + tCBPH + tRC + tCBPH);
        join
    end
    endtask

    /**************************************************************************
    *
    *  Figure 22: Asynchronous READ Using ADV#
    *
    **************************************************************************/

    task asynchronous_read_using_adv_n;
        input [addr_bits - 1 : 0] rd_addr;
    begin
        $display ($time," TB:ASYNC READ ADV CYCLE");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
            end
            begin : addr_blk 
                addr <= 'bz;
                addr <= #(tCBPH + tVP - tAVS) rd_addr;
                addr <= #(tCBPH + tVP + tAVH) 'bz;
            end
            begin : oe_blk 
                oe_n <= 1'b1; 
                oe_n <= #(tVPH + tAADV - tOE) 1'b0; 
                oe_n <= #(tVPH + tAADV) 1'b1; 
            end
            begin : adv_blk
                adv_n <= 1'b1;
                adv_n <= #(tCBPH) 1'b0;
                adv_n <= #(tCBPH + tVP) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(tCBPH) 1'b0;
                ce_n <= #(tCBPH + tRC + 10) 1'b1;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(tCBPH) 1'b0;
                lb_n <= #(tCBPH + tRC + 10) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(tCBPH) 1'b0;
                ub_n <= #(tCBPH + tRC + 10) 1'b1;
            end
           begin : we_blk 
                we_n <= 1'b1;
            end
            begin : dq_blk
                dq_out <= 'bz;
            end
            #(tCBPH + tRC + tCBPH + 10);
        join
    end
    endtask

    /**************************************************************************
    *
    *  Figure 23: Page Mode READ
    *
    **************************************************************************/

    task page_mode_read;
        input [addr_bits - 1 : 0] rd_addr0;
        input [addr_bits - 1 : 0] rd_addr1;
        input [addr_bits - 1 : 0] rd_addr2;
        input [addr_bits - 1 : 0] rd_addr3;
    begin
        $display ($time," TB:PAGE MODE READ");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
            end
            begin : addr_blk 
                addr <= 'bz;
                addr <= #(tCBPH) rd_addr0; 
                addr <= #(tCBPH + tRC) rd_addr1;
                addr <= #(tCBPH + tRC + 1 * tPC) rd_addr2;
                addr <= #(tCBPH + tRC + 2 * tPC) rd_addr3;
                addr <= #(tCBPH + tRC + 3 * tPC) 'bz;
            end
            begin : adv_blk
                adv_n <= 1'b1;
                adv_n <= #(tCBPH) 1'b0;
                adv_n <= #(tCBPH + tRC + 3 * tPC) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(tCBPH) 1'b0;
                ce_n <= #(tCBPH + tRC + 3 * tPC) 1'b1;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(tCBPH) 1'b0;
                lb_n <= #(tCBPH + tRC + 3 * tPC) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(tCBPH) 1'b0;
                ub_n <= #(tCBPH + tRC + 3 * tPC) 1'b1;
            end
            begin : oe_blk 
                oe_n <= 1'b0; 
            end
            begin : we_blk 
                we_n <= 1'b1;
            end
            begin : dq_blk
                dq_out <= 'bz;
            end
            #(tCBPH + tRC + 3 * tPC + tCBPH);
        join
    end
    endtask

    /**************************************************************************
    *
    *  Figure 29-31: Asynchronous WRITE cycle
    *
    **************************************************************************/

    task asynchronous_write_cycle;
        input [addr_bits - 1 : 0] wr_addr;
        input [data_bits - 1 : 0] wr_data;
    begin
        $display ($time," TB:ASYNC WRITE CYCLE");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
            end
            begin : addr_blk
                addr <= 'bz;
                addr <= #(tWPH) wr_addr;
                addr <= #(tWPH + tWC) 'bz;
            end
            begin : adv_blk
                adv_n <= 1'b1;
                adv_n <= #(tWPH) 1'b0;
                adv_n <= #(tWPH + tAW) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(tWPH) 1'b0; 
                ce_n <= #(tWPH + tCW) 1'b1;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(tWPH) 1'b0; 
                lb_n <= #(tWPH + tBW + tWPH) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(tWPH) 1'b0; 
                ub_n <= #(tWPH + tBW + tWPH) 1'b1;
            end
            begin : oe_blk 
                oe_n <= 1'b0; 
                oe_n <= #(tWPH + 5) 1'b1;
                oe_n <= #(tWPH + 10) 1'b0;
            end
            begin : we_blk 
                we_n <= 1'b1;
                we_n <= #(tWPH) 1'b0;
                we_n <= #(tWPH + tBW) 1'b1;
            end
            begin : dq_blk
                dq_out   <= 'bz;
                dq_out   <= #(tWPH + tBW - tDW) wr_data; 
                dq_out   <= #(tWPH + tBW + tDH) 'bz;
            end
            #(tWPH + tBW + tWPH);
        join
    end
    endtask

    /**************************************************************************
    *
    *  Figure 32.b: asynchronous WRITE Using ADV# CE_N controlled
    *
    **************************************************************************/

    task asynchronous_write_using_adv_n2;
        input [addr_bits - 1 : 0] wr_addr;
        input [data_bits - 1 : 0] wr_data;
    begin
        $display ($time," TB:ASYNC WRITE ADV CYCLE");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
            end
            begin : addr_blk
                addr <= 'bz;
                addr <= #(tVPH + tVP - tAVS) wr_addr;
                addr <= #(tVPH + tVP + tAVH) 'bz;
            end
            begin : adv_blk
                adv_n <= 1'b1;
                adv_n <= #(tVPH) 1'b0;
                adv_n <= #(tVPH + tVP) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(tVPH) 1'b0; 
                ce_n <= #(tVPH + tCW) 1'b1;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(tVPH) 1'b0; 
                lb_n <= #(tVPH + tBW + tWPH) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(tVPH) 1'b0; 
                ub_n <= #(tVPH + tBW + tWPH) 1'b1;
            end
            begin : oe_blk 
                oe_n <= 1'b0; 
                oe_n <= #(tVPH + 5) 1'b1;
                oe_n <= #(tVPH + 10) 1'b0;
            end
            begin : we_blk 
                we_n <= 1'b1;
                we_n <= #(tVPH) 1'b0;
                we_n <= #(tVPH + tBW + 5) 1'b1;
            end
            begin : dq_blk
                dq_out   <= 'bz;
                dq_out   <= #(tVPH + tBW - tDW) wr_data; 
                dq_out   <= #(tVPH + tBW + tDH) 'bz;
            end
            #(tVPH + tBW + tWPH);
        join
    end
    endtask


    /**************************************************************************
    *
    *  Figure 32: esynchronous WRITE Using ADV#
    *
    **************************************************************************/

    task asynchronous_write_using_adv_n;
        input [addr_bits - 1 : 0] wr_addr;
        input [data_bits - 1 : 0] wr_data;
    begin
        $display ($time," TB:ASYNC WRITE ADV CYCLE");
        fork
            begin : clk_blk
                clk <= 1'b0;
            end
            begin : cre_blk
                cre <= 1'b0;
            end
            begin : addr_blk
                addr <= 'bz;
                addr <= #(tVPH + tVP - tAVS) wr_addr;
                addr <= #(tVPH + tVP + tAVH) 'bz;
            end
            begin : adv_blk
                adv_n <= 1'b1;
                adv_n <= #(tVPH) 1'b0;
                adv_n <= #(tVPH + tVP) 1'b1;
            end
            begin : ce_blk 
                ce_n <= 1'b1;
                ce_n <= #(tVPH) 1'b0; 
                ce_n <= #(tVPH + tCW) 1'b1;
            end
            begin : lb_blk 
                lb_n <= 1'b1;
                lb_n <= #(tVPH) 1'b0; 
                lb_n <= #(tVPH + tBW + tWPH) 1'b1;
            end
            begin : ub_blk 
                ub_n <= 1'b1;
                ub_n <= #(tVPH) 1'b0; 
                ub_n <= #(tVPH + tBW + tWPH) 1'b1;
            end
            begin : oe_blk 
                oe_n <= 1'b0; 
                oe_n <= #(tVPH + 5) 1'b1;
                oe_n <= #(tVPH + 10) 1'b0;
            end
            begin : we_blk 
                we_n <= 1'b1;
                we_n <= #(tVPH) 1'b0;
                we_n <= #(tVPH + tBW) 1'b1;
                //we_n <= #(tVPH + tBW - tWP) 1'b0;
                //we_n <= #(tVPH + tBW) 1'b1;
            end
            begin : dq_blk
                dq_out   <= 'bz;
                dq_out   <= #(tVPH + tBW - tDW) wr_data; 
                dq_out   <= #(tVPH + tBW + tDH) 'bz;
            end
            #(tVPH + tBW + tWPH);
        join
    end
    endtask

    /**************************************************************************
    *                                                                         *
    *  Synchronous Configuration Register Task                                *
    *                                                                         *
    **************************************************************************/
    
    task sync_config_write;
        input [addr_bits - 1 : 0] config_data;
        begin
        $display ($time," TB:SYNC CONFIG WRITE");
            fork
                begin : clk_blk 
                    clk <= #(0.5 * tCLK) 1'b1; 
                    clk <= #(1.0 * tCLK) 1'b0; 
                    clk <= #(1.5 * tCLK) 1'b1; 
                    clk <= #(2.0 * tCLK) 1'b0; 
                    clk <= #(2.5 * tCLK) 1'b1; 
                    clk <= #(3.0 * tCLK) 1'b0; 
                    clk <= #(3.5 * tCLK) 1'b1; 
                    clk <= #(4.0 * tCLK) 1'b0; 
                    clk <= #(4.5 * tCLK) 1'b1; 
                    clk <= #(5.0 * tCLK) 1'b0; 
                    clk <= #(5.5 * tCLK) 1'b1; 
                    clk <= #(6.0 * tCLK) 1'b0; 
                    clk <= #(6.5 * tCLK) 1'b1; 
                    clk <= #(7.0 * tCLK) 1'b0; 
                    clk <= #(7.5 * tCLK) 1'b1; 
                    clk <= #(8.0 * tCLK) 1'b0; 
                    clk <= #(8.5 * tCLK) 1'b1; 
                    clk <= #(9.0 * tCLK) 1'b0; 
                    //clk <= #(9.5 * tCLK) 1'b1; 
                    //clk <= #(10.0 * tCLK) 1'b0; 
                    //clk <= #(10.5 * tCLK) 1'b1; 
                    //clk <= #(11.0 * tCLK) 1'b0; 
                    //clk <= #(11.5 * tCLK) 1'b1; 
                    //clk <= #(12.0 * tCLK) 1'b0; 
                    //clk <= #(12.5 * tCLK) 1'b1; 
                    //clk <= #(13.0 * tCLK) 1'b0; 
                    //clk <= #(13.5 * tCLK) 1'b1; 
                    //clk <= #(14.0 * tCLK) 1'b0; 
                    //clk <= #(14.5 * tCLK) 1'b1; 
                    //clk <= #(15.0 * tCLK) 1'b0; 
                    //clk <= #(15.5 * tCLK) 1'b1; 
                    //clk <= #(16.0 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= config_data; 
                end
                begin : cre_blk 
                    cre <= #(0.0 * tCLK) 1'b1; 
                    cre <= #(1.0 * tCLK) 1'b0;
                end
                begin : adv_blk 
                    adv_n <= #(0.0 * tCLK) 1'b0;
                    adv_n <= #(1.0 * tCLK) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #(0.0 * tCLK) 1'b0; 
                    ce_n <= #(8.0 * tCLK) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= 1'b1; 
                end
                begin : we_blk 
                    we_n <= #(0.0 * tCLK) 1'b0; 
                    we_n <= #(1.0 * tCLK) 1'b1;
                end
                begin : lb_ub_blk 
                    lb_n <= 1'b1; 
                    ub_n <= 1'b1; 
                end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}}; 
                end
                #(8.0 * tCLK);

                // Record latency counter for future use
                if (config_data[19] === 1) begin
                    latency_counter = config_data [13 : 11];
                end
            join
        end
    endtask

    /**************************************************************************
    *
    *  Figure 33_not: Synchronous Write Operation with UB/LB
    *
    **************************************************************************/
    
    task synchronous_write_operation_b;
        input [addr_bits - 1 : 0] addr_in;
        input [data_bits - 1 : 0] data0;
        input [data_bits - 1 : 0] data1;
        input [data_bits - 1 : 0] data2;
        input [data_bits - 1 : 0] data3;
        input [1:0] b_n0;
        input [1:0] b_n1;
        input [1:0] b_n2;
        input [1:0] b_n3;
        integer                   count;
        begin
            $display ($time," TB:SYNC WRITE");
            fork
                begin : clk_blk 
                    clk <= 1'b1; 
                    clk <= #( 0.5 * tCLK) 1'b0; 
                    clk <= #( 1.0 * tCLK) 1'b1; 
                    clk <= #( 1.5 * tCLK) 1'b0; 
                    clk <= #( 2.0 * tCLK) 1'b1; 
                    clk <= #( 2.5 * tCLK) 1'b0; 
                    clk <= #( 3.0 * tCLK) 1'b1; 
                    clk <= #( 3.5 * tCLK) 1'b0; 
                    clk <= #( 4.0 * tCLK) 1'b1; 
                    clk <= #( 4.5 * tCLK) 1'b0; 
                    clk <= #( 5.0 * tCLK) 1'b1; 
                    clk <= #( 5.5 * tCLK) 1'b0; 
                    clk <= #( 6.0 * tCLK) 1'b1; 
                    clk <= #( 6.5 * tCLK) 1'b0; 
                    clk <= #( 7.0 * tCLK) 1'b1; 
                    clk <= #( 7.5 * tCLK) 1'b0; 
                    clk <= #( 8.0 * tCLK) 1'b1; 
                    clk <= #( 8.5 * tCLK) 1'b0; 
                    clk <= #( 9.0 * tCLK) 1'b1; 
                    clk <= #( 9.5 * tCLK) 1'b0; 
                    clk <= #(10.0 * tCLK) 1'b1; 
                    clk <= #(10.5 * tCLK) 1'b0; 
                    clk <= #(11.0 * tCLK) 1'b1; 
                    clk <= #(11.5 * tCLK) 1'b0; 
                    clk <= #(12.0 * tCLK) 1'b1; 
                    clk <= #(12.5 * tCLK) 1'b0; 
                    clk <= #(13.0 * tCLK) 1'b1; 
                    clk <= #(13.5 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= addr_in; 
                end
                begin : cre_blk 
                    cre <= #(0.5 * tCLK) 1'b0; 
                end
                begin : adv_blk 
                    adv_n <= #(0.5 * tCLK) 1'b0;
                    adv_n <= #(1.5 * tCLK) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #( 0.5 * tCLK) 1'b0;
                    //ce_n <= #(12.5 * tCLK) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= #(0.5 * tCLK) 1'b1; 
                end
                begin : we_blk 
                    we_n <= #( 0.5 * tCLK) 1'b0; 
                    we_n <= #(13.5 * tCLK) 1'b1;
                end
                //begin : lb_ub_blk
                    //lb_n <= #(0.5 * tCLK) 1'b0; 
                    //ub_n <= #(0.5 * tCLK) 1'b0; 
                //end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}};
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk) dq_out <= data0;
                    ub_n <= b_n0[0];
                    lb_n <= b_n0[1];
                    count = 1;
                    while (count < 5) begin
                        @ (posedge clk);
                        if (owait_verilog === 1'b1) begin
                            @ (negedge clk) begin
                                case (count)
                                    1 : begin
                                            dq_out <= data1;
                                            ub_n <= b_n1[0];
                                            lb_n <= b_n1[1];
                                        end
                                    2 : begin
                                            dq_out <= data2;
                                            ub_n <= b_n2[0];
                                            lb_n <= b_n2[1];
                                        end
                                    3 : begin
                                            dq_out <= data3;
                                            ub_n <= b_n3[0];
                                            lb_n <= b_n3[1];
                                        end
                                    4 : begin
                                            dq_out <= 16'bz;
                                            ub_n <= 1'bz;
                                            lb_n <= 1'bz;
                                            ce_n <= 1'b1;
                                            //lb_n <= 1'b1; 
                                            //ub_n <= 1'b1;
                                        end
                                endcase
                                count = count + 1;
                            end
                        end
                    end
                end
                #(14.0 * tCLK);
            join
        end
    endtask


    /**************************************************************************
    *
    *  Figure 33: Synchronous Write Operation
    *
    **************************************************************************/
    
    task synchronous_write_operation;
        input [addr_bits - 1 : 0] addr_in;
        input [data_bits - 1 : 0] data0;
        input [data_bits - 1 : 0] data1;
        input [data_bits - 1 : 0] data2;
        input [data_bits - 1 : 0] data3;
        integer                   count;
        begin
            $display ($time," TB:SYNC WRITE");
            fork
                begin : clk_blk 
                    clk <= 1'b1; 
                    clk <= #( 0.5 * tCLK) 1'b0; 
                    clk <= #( 1.0 * tCLK) 1'b1; 
                    clk <= #( 1.5 * tCLK) 1'b0; 
                    clk <= #( 2.0 * tCLK) 1'b1; 
                    clk <= #( 2.5 * tCLK) 1'b0; 
                    clk <= #( 3.0 * tCLK) 1'b1; 
                    clk <= #( 3.5 * tCLK) 1'b0; 
                    clk <= #( 4.0 * tCLK) 1'b1; 
                    clk <= #( 4.5 * tCLK) 1'b0; 
                    clk <= #( 5.0 * tCLK) 1'b1; 
                    clk <= #( 5.5 * tCLK) 1'b0; 
                    clk <= #( 6.0 * tCLK) 1'b1; 
                    clk <= #( 6.5 * tCLK) 1'b0; 
                    clk <= #( 7.0 * tCLK) 1'b1; 
                    clk <= #( 7.5 * tCLK) 1'b0; 
                    clk <= #( 8.0 * tCLK) 1'b1; 
                    clk <= #( 8.5 * tCLK) 1'b0; 
                    clk <= #( 9.0 * tCLK) 1'b1; 
                    clk <= #( 9.5 * tCLK) 1'b0; 
                    clk <= #(10.0 * tCLK) 1'b1; 
                    clk <= #(10.5 * tCLK) 1'b0; 
                    clk <= #(11.0 * tCLK) 1'b1; 
                    clk <= #(11.5 * tCLK) 1'b0; 
                    clk <= #(12.0 * tCLK) 1'b1; 
                    clk <= #(12.5 * tCLK) 1'b0; 
                    clk <= #(13.0 * tCLK) 1'b1; 
                    clk <= #(13.5 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= addr_in; 
                end
                begin : cre_blk 
                    cre <= #(0.5 * tCLK) 1'b0; 
                end
                begin : adv_blk 
                    adv_n <= #(0.5 * tCLK) 1'b0;
                    adv_n <= #(1.5 * tCLK) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #( 0.5 * tCLK) 1'b0;
                    //ce_n <= #(12.5 * tCLK) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= #(0.5 * tCLK) 1'b1; 
                end
                begin : we_blk 
                    we_n <= #( 0.5 * tCLK) 1'b0; 
                    we_n <= #(13.5 * tCLK) 1'b1;
                end
                begin : lb_ub_blk
                    lb_n <= #(0.5 * tCLK) 1'b0; 
                    ub_n <= #(0.5 * tCLK) 1'b0; 
                end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}};
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk) dq_out <= data0;
                    count = 1;
                    while (count < 5) begin
                        @ (posedge clk);
                        if (owait_verilog === 1'b1) begin
                            @ (negedge clk) begin
                                case (count)
                                    1 : dq_out <= data1;
                                    2 : dq_out <= data2;
                                    3 : dq_out <= data3;
                                    4 : begin
                                            dq_out <= 16'bz;
                                            ce_n <= 1'b1;
                                            //lb_n <= 1'b1; 
                                            //ub_n <= 1'b1;
                                        end
                                endcase
                                count = count + 1;
                            end
                        end
                    end
                end
                #(14.0 * tCLK);
            join
        end
    endtask

    /**************************************************************************
    *
    *  Figure 33: Synchronous Write Operation burst
    *
    **************************************************************************/
    
    task synchronous_write_operation_burst;
        input [addr_bits - 1 : 0] burst_length;
        input [addr_bits - 1 : 0] addr_in;
        input [data_bits - 1 : 0] data0;
        input [data_bits - 1 : 0] data1;
        input [data_bits - 1 : 0] data2;
        input [data_bits - 1 : 0] data3;
        integer                   count;
        begin
            $display ($time," TB:SYNC WRITE BURST");
            fork
                begin : clk_blk 
                    clk <= 1'b1; 
                    clk <= #( 0.5 * tCLK) 1'b0; 
                    clk <= #( 1.0 * tCLK) 1'b1; 
                    clk <= #( 1.5 * tCLK) 1'b0; 
                    clk <= #( 2.0 * tCLK) 1'b1; 
                    clk <= #( 2.5 * tCLK) 1'b0; 
                    clk <= #( 3.0 * tCLK) 1'b1; 
                    clk <= #( 3.5 * tCLK) 1'b0; 
                    clk <= #( 4.0 * tCLK) 1'b1; 
                    clk <= #( 4.5 * tCLK) 1'b0; 
                    clk <= #( 5.0 * tCLK) 1'b1; 
                    clk <= #( 5.5 * tCLK) 1'b0; 
                    clk <= #( 6.0 * tCLK) 1'b1; 
                    clk <= #( 6.5 * tCLK) 1'b0; 
                    clk <= #( 7.0 * tCLK) 1'b1; 
                    clk <= #( 7.5 * tCLK) 1'b0; 
                    clk <= #( 8.0 * tCLK) 1'b1; 
                    clk <= #( 8.5 * tCLK) 1'b0; 
                    clk <= #( 9.0 * tCLK) 1'b1; 
                    clk <= #( 9.5 * tCLK) 1'b0; 
                    clk <= #(10.0 * tCLK) 1'b1; 
                    clk <= #(10.5 * tCLK) 1'b0; 
                    clk <= #(11.0 * tCLK) 1'b1; 
                    clk <= #(11.5 * tCLK) 1'b0; 
                    clk <= #(12.0 * tCLK) 1'b1; 
                    clk <= #(12.5 * tCLK) 1'b0; 
                    clk <= #(13.0 * tCLK) 1'b1; 
                    clk <= #(13.5 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= addr_in; 
                end
                begin : cre_blk 
                    cre <= #(0.5 * tCLK) 1'b0; 
                end
                begin : adv_blk 
                    adv_n <= #(0.5 * tCLK) 1'b0;
                    adv_n <= #(1.5 * tCLK) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #( 0.5 * tCLK) 1'b0;
                    //ce_n <= #(12.5 * tCLK) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= #(0.5 * tCLK) 1'b1; 
                end
                begin : we_blk 
                    we_n <= #( 0.5 * tCLK) 1'b0; 
                    we_n <= #(13.5 * tCLK) 1'b1;
                end
                begin : lb_ub_blk
                    lb_n <= #(0.5 * tCLK) 1'b0; 
                    ub_n <= #(0.5 * tCLK) 1'b0; 
                end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}};
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk);
                    @ (posedge clk);
                    @ (negedge clk) dq_out <= data0;
                    count = 1;
                    while (count < burst_length) begin
                        @ (posedge clk);
                        if (owait_verilog === 1'b1) begin
                            @ (negedge clk) begin
                                case (count)
                                    1 : dq_out <= data1;
                                    2 : dq_out <= data2;
                                    3 : dq_out <= data3;
                                    4 : begin
                                            dq_out <= 16'bz;
                                            ce_n <= 1'b1;
                                            //lb_n <= 1'b1; 
                                            //ub_n <= 1'b1;
                                        end
                                endcase
                                count = count + 1;
                            end
                        end
                    end
                end
                #(14.0 * tCLK);
            join
        end
    endtask

    /**************************************************************************
    *
    *  Figure 15: Synchronous Config Read Operation
    *
    **************************************************************************/
    
    task sync_config_read;
        input [1 : 0] which_register;
        begin
            $display ($time," TB:SYNC CONFIG READ");
            fork
                begin : clk_blk 
                    clk <= 1'b0; 
                    clk <= #( 0.5 * tCLK) 1'b1; 
                    clk <= #( 1.0 * tCLK) 1'b0; 
                    clk <= #( 1.5 * tCLK) 1'b1; 
                    clk <= #( 2.0 * tCLK) 1'b0; 
                    clk <= #( 2.5 * tCLK) 1'b1; 
                    clk <= #( 3.0 * tCLK) 1'b0; 
                    clk <= #( 3.5 * tCLK) 1'b1; 
                    clk <= #( 4.0 * tCLK) 1'b0; 
                    clk <= #( 4.5 * tCLK) 1'b1; 
                    clk <= #( 5.0 * tCLK) 1'b0; 
                    clk <= #( 5.5 * tCLK) 1'b1; 
                    clk <= #( 6.0 * tCLK) 1'b0; 
                    clk <= #( 6.5 * tCLK) 1'b1; 
                    clk <= #( 7.0 * tCLK) 1'b0; 
                    clk <= #( 7.5 * tCLK) 1'b1; 
                    clk <= #( 8.0 * tCLK) 1'b0; 
                    clk <= #( 8.5 * tCLK) 1'b1; 
                    clk <= #( 9.0 * tCLK) 1'b0; 
                    clk <= #( 9.5 * tCLK) 1'b1; 
                    clk <= #(10.0 * tCLK) 1'b0; 
                    clk <= #(10.5 * tCLK) 1'b1; 
                    clk <= #(11.0 * tCLK) 1'b0; 
                    clk <= #(11.5 * tCLK) 1'b1; 
                    clk <= #(12.0 * tCLK) 1'b0; 
                    clk <= #(12.5 * tCLK) 1'b1; 
                    clk <= #(13.0 * tCLK) 1'b0; 
                    clk <= #(13.5 * tCLK) 1'b1; 
                    clk <= #(14.0 * tCLK) 1'b0; 
                    clk <= #(14.5 * tCLK) 1'b1; 
                    clk <= #(15.0 * tCLK) 1'b0; 
                    clk <= #(15.5 * tCLK) 1'b1; 
                    clk <= #(16.0 * tCLK) 1'b0; 
                    clk <= #(16.5 * tCLK) 1'b1; 
                    clk <= #(17.0 * tCLK) 1'b0; 
                    clk <= #(17.5 * tCLK) 1'b1; 
                    clk <= #(18.0 * tCLK) 1'b0; 
                    clk <= #(18.5 * tCLK) 1'b1; 
                    clk <= #(19.0 * tCLK) 1'b0; 
                    clk <= #(19.5 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= #(3.5 * tCLK) 'b0;
                    addr[19:18] <= #(3.5 * tCLK) which_register; 
                end
                begin : cre_blk 
                    cre <=  1'b0;
                    cre <=  #(3.5 * tCLK)1'b1;
                    //cre <= #(0.5 * tCLK) 1'b0; 
                    //cre <= #(3+(0.5 * tCLK)) 1'b0; 
                    cre <= #((3.5 * tCLK) + tRC+30) 1'b0; 
                end
                begin : adv_blk 
                    adv_n <= #(3.5 * tCLK) 1'b0;
                    adv_n <= #((3 *tCLK) + (1.5 * tCLK)) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #(3.5 * tCLK) 1'b0;
                    ce_n <= #((5 * tCLK) + (8 * tCLK)) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= 1'b1; 
                    oe_n <= #((3 * tCLK) + (1.5 * tCLK)) 1'b0; 
                end
                begin : we_blk 
                    we_n <= #(3 * tCLK) 1'b1; 
                end
                begin : lb_ub_blk
                    lb_n <= 1'b1; 
                    ub_n <= 1'b1; 
                    lb_n <= #(3.5 * tCLK) 1'b0; 
                    ub_n <= #(3.5 * tCLK) 1'b0; 
                end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}};
                end
                #(20.0 * tCLK);
            join
        end
    endtask


    /**************************************************************************
    *
    *  Figure 26: Synchronous Read Operation
    *
    **************************************************************************/
    
    task synchronous_read_operation;
        input [addr_bits - 1 : 0] addr_in;
        begin
            $display ($time," TB:SYNC READ");
            fork
                begin : clk_blk 
                    clk <= 1'b1; 
                    clk <= #( 0.5 * tCLK) 1'b0; 
                    clk <= #( 1.0 * tCLK) 1'b1; 
                    clk <= #( 1.5 * tCLK) 1'b0; 
                    clk <= #( 2.0 * tCLK) 1'b1; 
                    clk <= #( 2.5 * tCLK) 1'b0; 
                    clk <= #( 3.0 * tCLK) 1'b1; 
                    clk <= #( 3.5 * tCLK) 1'b0; 
                    clk <= #( 4.0 * tCLK) 1'b1; 
                    clk <= #( 4.5 * tCLK) 1'b0; 
                    clk <= #( 5.0 * tCLK) 1'b1; 
                    clk <= #( 5.5 * tCLK) 1'b0; 
                    clk <= #( 6.0 * tCLK) 1'b1; 
                    clk <= #( 6.5 * tCLK) 1'b0; 
                    clk <= #( 7.0 * tCLK) 1'b1; 
                    clk <= #( 7.5 * tCLK) 1'b0; 
                    clk <= #( 8.0 * tCLK) 1'b1; 
                    clk <= #( 8.5 * tCLK) 1'b0; 
                    clk <= #( 9.0 * tCLK) 1'b1; 
                    clk <= #( 9.5 * tCLK) 1'b0; 
                    clk <= #(10.0 * tCLK) 1'b1; 
                    clk <= #(10.5 * tCLK) 1'b0; 
                    clk <= #(11.0 * tCLK) 1'b1; 
                    clk <= #(11.5 * tCLK) 1'b0; 
                    clk <= #(12.0 * tCLK) 1'b1; 
                    clk <= #(12.5 * tCLK) 1'b0; 
                    clk <= #(13.0 * tCLK) 1'b1; 
                    clk <= #(13.5 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= addr_in; 
                end
                begin : cre_blk 
                    cre <= #(0.5 * tCLK) 1'b0; 
                end
                begin : adv_blk 
                    adv_n <= #(0.5 * tCLK) 1'b0;
                    adv_n <= #(1.5 * tCLK) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #( 0.5 * tCLK) 1'b0;
                    ce_n <= #(12.5 * tCLK) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= #( 0.5 * tCLK) 1'b0; 
                end
                begin : we_blk 
                    we_n <= #(0.5 * tCLK) 1'b1; 
                end
                begin : lb_ub_blk
                    lb_n <= #(0.5 * tCLK) 1'b0; 
                    ub_n <= #(0.5 * tCLK) 1'b0; 
                end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}};
                end
                #(14.0 * tCLK);
            join
        end
    endtask

    /**************************************************************************
    *
    *  Figure 26: Synchronous Read Operation with UB/LB
    *
    **************************************************************************/
    
    task synchronous_read_operation_b;
        input [addr_bits - 1 : 0] addr_in;
        input [1:0] b_n0;
        input [1:0] b_n1;
        input [1:0] b_n2;
        input [1:0] b_n3;
        input [1:0] b_n4;
        input [1:0] b_n5;
        input [1:0] b_n6;
        input [1:0] b_n7;
        begin
            $display ($time," TB:SYNC READ");
            fork
                begin : clk_blk 
                    clk <= 1'b1; 
                    clk <= #( 0.5 * tCLK) 1'b0; 
                    clk <= #( 1.0 * tCLK) 1'b1; 
                    clk <= #( 1.5 * tCLK) 1'b0; 
                    clk <= #( 2.0 * tCLK) 1'b1; 
                    clk <= #( 2.5 * tCLK) 1'b0; 
                    clk <= #( 3.0 * tCLK) 1'b1; 
                    clk <= #( 3.5 * tCLK) 1'b0; 
                    clk <= #( 4.0 * tCLK) 1'b1; 
                    clk <= #( 4.5 * tCLK) 1'b0; 
                    clk <= #( 5.0 * tCLK) 1'b1; 
                    clk <= #( 5.5 * tCLK) 1'b0; 
                    clk <= #( 6.0 * tCLK) 1'b1; 
                    clk <= #( 6.5 * tCLK) 1'b0; 
                    clk <= #( 7.0 * tCLK) 1'b1; 
                    clk <= #( 7.5 * tCLK) 1'b0; 
                    clk <= #( 8.0 * tCLK) 1'b1; 
                    clk <= #( 8.5 * tCLK) 1'b0; 
                    clk <= #( 9.0 * tCLK) 1'b1; 
                    clk <= #( 9.5 * tCLK) 1'b0; 
                    clk <= #(10.0 * tCLK) 1'b1; 
                    clk <= #(10.5 * tCLK) 1'b0; 
                    clk <= #(11.0 * tCLK) 1'b1; 
                    clk <= #(11.5 * tCLK) 1'b0; 
                    clk <= #(12.0 * tCLK) 1'b1; 
                    clk <= #(12.5 * tCLK) 1'b0; 
                    clk <= #(13.0 * tCLK) 1'b1; 
                    clk <= #(13.5 * tCLK) 1'b0; 
                end
                begin : addr_blk 
                    addr <= addr_in; 
                end
                begin : cre_blk 
                    cre <= #(0.5 * tCLK) 1'b0; 
                end
                begin : adv_blk 
                    adv_n <= #(0.5 * tCLK) 1'b0;
                    adv_n <= #(1.5 * tCLK) 1'b1;
                end
                begin : ce_blk 
                    ce_n <= #( 0.5 * tCLK) 1'b0;
                    ce_n <= #(12.5 * tCLK) 1'b1;
                end
                begin : oe_blk 
                    oe_n <= #( 0.5 * tCLK) 1'b0; 
                end
                begin : we_blk 
                    we_n <= #(0.5 * tCLK) 1'b1; 
                end
                begin : lb_ub_blk
                    lb_n <= #(0.5 * tCLK) b_n0[0]; 
                    ub_n <= #(0.5 * tCLK) b_n0[1]; 
                    lb_n <= #(1.5 * tCLK) b_n1[0]; 
                    ub_n <= #(1.5 * tCLK) b_n1[1]; 
                    lb_n <= #(2.5 * tCLK) b_n2[0]; 
                    ub_n <= #(2.5 * tCLK) b_n2[1]; 
                    lb_n <= #(3.5 * tCLK) b_n3[0]; 
                    ub_n <= #(3.5 * tCLK) b_n3[1]; 
                    lb_n <= #(4.5 * tCLK) b_n4[0]; 
                    ub_n <= #(4.5 * tCLK) b_n4[1]; 
                    lb_n <= #(5.5 * tCLK) b_n5[0]; 
                    ub_n <= #(5.5 * tCLK) b_n5[1]; 
                    lb_n <= #(6.5 * tCLK) b_n6[0]; 
                    ub_n <= #(6.5 * tCLK) b_n6[1]; 
                    lb_n <= #(7.5 * tCLK) b_n7[0]; 
                    ub_n <= #(7.5 * tCLK) b_n7[1]; 
                end
                begin : dq_blk 
                    dq_out <= {data_bits{1'bz}};
                end
                #(14.0 * tCLK);
            join
        end
    endtask


    /**************************************************************************
    *
    * Similar to figure 36: Asynchonous WRITE Followed by Burst READ
    *
    **************************************************************************/

    task asynchronous_write_followed_by_burst_read;
        input [addr_bits - 1 : 0] wr_addr0;
        input [data_bits - 1 : 0] wr_data0;
        input [addr_bits - 1 : 0] wr_addr1;
        input [data_bits - 1 : 0] wr_data1;
        input [addr_bits - 1 : 0] rd_addr2;
    begin
        $display ($time," TB:SYNC WRITE FOLLOWED BY BURST READ");
        asynchronous_write_using_adv_n (wr_addr0, wr_data0);
        asynchronous_write_using_adv_n (wr_addr1, wr_data1);
        #tCKA;
        synchronous_read_operation (rd_addr2);
    end
    endtask

    integer i;

    /**************************************************************************
    *
    *               TEST VECTORS
    *
    **************************************************************************/

    initial begin
        initialization_period;            //    210 98 76 5 4 321 0 9 8 76 54 3 210 
                         async_config_write(23'b000_10_00_1_0_011_0_0_0_00_10_1_010);
        //                                       |  |  |  | |  |  | | |  | |  |  |               
        //  FIRST   *BCR REG DEF*                |  |  |  | |  |  | | |  | |  |  --------------->Burst Length:
        //  LOOK                                 |  |  |  | |  |  | | |  | |  |                  001    =>  4 words 
        //  HERE                                 |  |  |  | |  |  | | |  | |  |                  010    =>  8 words
        //   |           Reserved set to 000 <----  |  |  | |  |  | | |  | |  |                  011    => 16 words
        //   |                                      |  |  | |  |  | | |  | |  -> 0=Burst Wrap    100    => 32 words *CR1.5* ONLY
        //   |        Register Select  <-------------  |  | |  |  | | |  | |     1=No Wrap       111    => continuous (default)
        //   |        00=RCR                           |  | |  |  | | |  | |                     OTHERS => reserved 
        //   -------->10=BCR                           |  | |  |  | | |  | -> *CR1.5* Drv Strngth
        //            01=DIDR *CR1.5* ONLY             |  | |  |  | | |  | |  00 = Full
        //                                             |  | |  |  | | |  | |  01 = 1/2 (default) ---> *CR1.0* Drv Strngth
        //                                             |  | |  |  | | |  | |  10 = 1/4           |    BCR[4]=reserved
        //              Reserved set to 00 <------------  | |  |  | | |  | |  11 = reserved      |    BCR[5]=0=Full
        //                                                | |  |  | | |  | -----------------------    BCR[5]=1=1/4
        //                     Operating Mode      <------- |  |  | | |  ->  Reserved set to 00's
        //                     0=Synchronous burst          |  |  | | |      
        //                     1=Asynchronous (defalut)     |  |  | | ->  Wait  
        //                                                  |  |  | |     0 = Asserted during delay
        //                    Initial Latency      <---------  |  | |     1 = Asserted one data cycle before delay (default)
        //                    0=Variable(Default)              |  | |    
        //                    1=Fixed *CR1.5* ONLY             |  | ->  Reserved set to 0
        //                                                     |  |     
        //                                                     |  ---------------------------->  Wait Polarity
        //                                                     |                                 0=Active LOW
        //                                                     - >  Latency counter              1=Active HIGH (default)
        //                                                          010=Code 2
        //                                                          011=Code 3(default)
        //                                                          100=Code 4
        //                                                          101=Code 5
        //                                                          110=Code 6
        //                                                          else=Reserved 
        //                                                   

        //synchronous_read_using_adv_n (32'h00000000); //rd_addr;

                                          //    210 98 7654321098 7 65 4 3 210 
                         async_config_write(23'b000_00_0000000000_0_00_1_0_100);
        //                                       |  |    |        |  | | |  |
        //  FIRST   *RCR REG DEF*                |  |    |        |  | | |  --------------> PAR 
        //  LOOK                                 |  |    |        |  | | |                  000 => Full array (default)
        //  HERE                                 |  |    |        |  | | |                  001 => Bottom 1/2
        //   |           Reserved set to 0   <----  |    |        |  | | -> Reserved        010 => Bottom 1/4
        //   |                                      |    |        |  | |                    011 => Bottom 1/8
        //   |        Register Select  <-------------    |        |  | -> Deep Pwr Down     100 => None
        //   |        00=RCR                             |        |  |    0=Deep Pwr Dn.    101 => Top 1/2
        //   -------->10=BCR                             |        |  |    1=Off (default)   110 => Top 1/4
        //            01=DIDR *CR1.5* ONLY               |        |  |                      111 => Top 1/8
        //                                               |        |  -> Reserved           
        //                                               |        |              
        //                                               |        --> Page Mode
        //                                               |            0-Disabled
        //               Reserved set to 0 <--------------            1-Enabled
        //                
                                        
#200
        //ASYNC register read
        async_config_read(2'b10); // 00=RCR, 10=BCR, 01=DIDR

#200
        //ASYNC read of mem RCR
        async_config_read(2'b00); // 00=RCR, 10=BCR, 01=DIDR

#200
        //ASYNC read of mem DIDR
        async_config_read(2'b01); // 00=RCR, 10=BCR, 01=DIDR
#200

        //synchronous_write_operation_b (0,  16'h0000, 16'h1111, 16'h2222, 16'h3333, 1, 0, 0, 0); //Addr, D0, D1, D2, D3
        //synchronous_write_operation_b (4,  16'h4444, 16'h5555, 16'h6666, 16'h7777, 0, 1, 0, 0); //Addr, D0, D1, D2, D3
        //synchronous_read_operation_b (0, 0, 0, 0, 0, 0, 0, 0, 0);  //Addr, lb/ub 1-8 (associated with re_n pulse)
        //synchronous_read_operation_b (4, 0, 0, 0, 0, 0, 0, 0, 0);  //Addr, lb/ub 1-8 (associated with re_n pulse)

        #20  // Software write access to RCR Reg

                                         //    210 98 76 5 4 321 0 9 8 76 54 3 210 
        //                sync_config_write(23'b000_10_00_1_1_011_0_0_0_00_10_1_010);

        #200

        asynchronous_write_using_adv_n(0, 16'h0000);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n(1, 16'h1111);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n(2, 16'h2222);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n(3, 16'h3333);  // wr_addr, wr_data;

        asynchronous_read_using_adv_n(0);
        asynchronous_read_using_adv_n(1);
        asynchronous_read_using_adv_n(2);
        asynchronous_read_using_adv_n(3);

	asynchronous_write_cycle(4, 16'h4444);
	asynchronous_write_cycle(5, 16'h5555);
	asynchronous_write_cycle(6, 16'h6666);
	asynchronous_write_cycle(7, 16'h7777);

        asynchronous_read_cycle(4);
        asynchronous_read_cycle(5);
        asynchronous_read_cycle(6);
        asynchronous_read_cycle(7);

#200
        asynchronous_read_using_adv_n(2);
        asynchronous_read_using_adv_n(3);
        asynchronous_read_cycle(6);
        asynchronous_read_cycle(7);
#200

                         async_config_write(23'b000_10_00_0_0_011_0_0_0_00_10_1_010);
#200
        sync_config_read(2'b10); // 00=RCR, 10=BCR, 01=DIDR

#200
        sync_config_read(2'b00); // 00=RCR, 10=BCR, 01=DIDR

#200
        sync_config_read(2'b01); // 00=RCR, 10=BCR, 01=DIDR
#200



        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - WRITE BCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0001);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n (23'b11111111111111111111111, 16'b 1_1_011_0_0_0_00_00_0_001);  // wr_addr, wr_data;
                                                                    //    5 4 321 0 9 8 76 54 3 210 

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 2 - WRITE BCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0001);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n (23'b11111111111111111111111, 16'b 1_1_011_0_0_0_00_00_0_011);  // wr_addr, wr_data;
                                                                    //    5 4 321 0 9 8 76 54 3 210 

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 3 - WRITE BCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0001);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n (23'b11111111111111111111111, 16'b 1_1_011_0_0_0_00_00_0_100);  // wr_addr, wr_data;
                                                                    //    5 4 321 0 9 8 76 54 3 210 

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - WRITE RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n (23'b11111111111111111111111, 16'b00000000_1_00_1_0_001);  // wr_addr, wr_data;
                                                                   //    54321098 7 65 4 3 210 

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 2 - WRITE RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n (23'b11111111111111111111111, 16'b00000000_1_00_1_0_011);  // wr_addr, wr_data;
                                                                   //    54321098 7 65 4 3 210 

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 3 - WRITE RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n (23'b11111111111111111111111, 16'b00000000_1_00_1_0_101);  // wr_addr, wr_data;
                                                                   //    54321098 7 65 4 3 210 

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 3 - READ DIDR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0002);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - READ RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 3 - READ DIDR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n2(23'b11111111111111111111111, 16'h0002);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - READ BCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n2(23'b11111111111111111111111, 16'h0001);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - READ RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n2(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - READ RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n2(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 3 - READ DIDR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n2(23'b11111111111111111111111, 16'h0002);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - READ RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n2(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 2 - READ BCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0001);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 3 - READ DIDR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0002);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;

        #200
        $display ($time," TB:ASYNC SOFTWARE ACCESS 1 - READ RCR");
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_read_using_adv_n(23'b11111111111111111111111);  // wr_addr
        asynchronous_write_using_adv_n(23'b11111111111111111111111, 16'h0000);  // wr_addr, wr_data;
        asynchronous_read_using_adv_n (23'b11111111111111111111111);  // wr_addr, wr_data;


        #200
                         async_config_write(23'b000_10_00_0_0_011_0_0_0_00_10_1_010);

        synchronous_write_operation (0,  16'h0000, 16'h1111, 16'h2222, 16'h3333); //Addr, D0, D1, D2, D3
        synchronous_write_operation (4,  16'h4444, 16'h5555, 16'h6666, 16'h7777); //Addr, D0, D1, D2, D3

        synchronous_read_operation (0);  //Addr
        synchronous_read_operation (4);  //Addr

        asynchronous_write_using_adv_n(0, 16'h0000);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n(1, 16'h1111);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n(2, 16'h2222);  // wr_addr, wr_data;
        asynchronous_write_using_adv_n(3, 16'h3333);  // wr_addr, wr_data;

        asynchronous_read_using_adv_n(0);
        asynchronous_read_using_adv_n(1);
        asynchronous_read_using_adv_n(2);
        asynchronous_read_using_adv_n(3);

        synchronous_write_operation (0, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3
        synchronous_write_operation (4, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3
        synchronous_write_operation (8, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3
        synchronous_write_operation (12, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3

        synchronous_read_operation (0);  //Addr
        synchronous_read_operation (4);  //Addr
        synchronous_read_operation (8);  //Addr
        synchronous_read_operation (12);  //Addr

if (0) begin
        //asynchronous_write_using_adv_n(0, 16'h0000);  // wr_addr, wr_data;
        //asynchronous_write_using_adv_n(1, 16'h1111);  // wr_addr, wr_data;
        //asynchronous_write_using_adv_n(2, 16'h2222);  // wr_addr, wr_data;
        //asynchronous_write_using_adv_n(3, 16'h3333);  // wr_addr, wr_data;

        //asynchronous_read_using_adv_n(0);
        //asynchronous_read_using_adv_n(1);
        //asynchronous_read_using_adv_n(2);
        //asynchronous_read_using_adv_n(3);

        //synchronous_write_operation (0, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3
        //synchronous_write_operation (4, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3
        //synchronous_write_operation (8, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3
        //synchronous_write_operation (12, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3

        //synchronous_read_operation (0);  //Addr
        //synchronous_read_operation (4);  //Addr
        //synchronous_read_operation (8);  //Addr
        //synchronous_read_operation (12);  //Addr

        //for (i = 0; i <= 5; i = i + 1) ge
            //begin                                
                //$display ("");
                 //$display ("Random %d:", i); 
                 //synchronous_write_operation (i, {$random} % 65536, {$random} % 65536, {$random} % 65536, {$random} % 65536); //Addr, D0, D1, D2, D3

                 //synchronous_write_operation (0, 65535, 0, 21845, 43690);   // FFFF, 0000, 5555, AAAA
                 //synchronous_read_operation (0);  //Addr

                 //synchronous_write_operation (1, 0, 1, 2, 3); 
                 //synchronous_read_operation (1);  //Addr
            //end

        //synchronous_write_operation (0, 16'h0, 16'h0, 16'h0, 16'h0 ); 
        //synchronous_read_operation (0); synchronous_read_operation (1); synchronous_read_operation (2); synchronous_read_operation (3);
        //synchronous_read_operation (4); synchronous_read_operation (5); synchronous_read_operation (6); synchronous_read_operation (7);
        //synchronous_write_operation (1, 16'h5555, 16'h5555, 16'h5555, 16'h5555 ); synchronous_read_operation (1);
        //synchronous_write_operation (2, 16'hAAAA, 16'hAAAA, 16'hAAAA, 16'hAAAA ); synchronous_read_operation (2);
        //synchronous_write_operation (3, 16'hFFFF, 16'hFFFF, 16'hFFFF, 16'hFFFF ); synchronous_read_operation (3);
        

        #200;
        end
        $display("At time %t: SIMULATION ENDING NORMALLY", $time);
        //$stop;
        //$finish;
    end

endmodule
