--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

--/****************************************************************************************
--*
--*   Disclaimer   This software code and all associated documentation, comments or other 
--*  of Warranty:  information (collectively "Software") is provided "AS IS" without 
--*                warranty of any kind. MICRON TECHNOLOGY, INC. ("MTI") EXPRESSLY 
--*                DISCLAIMS ALL WARRANTIES EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
--*                TO, NONINFRINGEMENT OF THIRD PARTY RIGHTS, AND ANY IMPLIED WARRANTIES 
--*                OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. MTI DOES NOT 
--*                WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS, OR THAT THE 
--*                OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE. 
--*                FURTHERMORE, MTI DOES NOT MAKE ANY REPRESENTATIONS REGARDING THE USE OR 
--*                THE RESULTS OF THE USE OF THE SOFTWARE IN TERMS OF ITS CORRECTNESS, 
--*                ACCURACY, RELIABILITY, OR OTHERWISE. THE ENTIRE RISK ARISING OUT OF USE 
--*                OR PERFORMANCE OF THE SOFTWARE REMAINS WITH YOU. IN NO EVENT SHALL MTI, 
--*                ITS AFFILIATED COMPANIES OR THEIR SUPPLIERS BE LIABLE FOR ANY DIRECT, 
--*                INDIRECT, CONSEQUENTIAL, INCIDENTAL, OR SPECIAL DAMAGES (INCLUDING, 
--*                WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, BUSINESS INTERRUPTION, 
--*                OR LOSS OF INFORMATION) ARISING OUT OF YOUR USE OF OR INABILITY TO USE 
--*                THE SOFTWARE, EVEN IF MTI HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
--*                DAMAGES. Because some jurisdictions prohibit the exclusion or 
--*                limitation of liability for consequential or incidental damages, the 
--*                above limitation may not apply to you.
--*
--*                Copyright 2005 Micron Technology, Inc. All rights reserved.
--*
--****************************************************************************************/

-- Timing parameters based on Speed Grade

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package micron_mem_parameters is

  -- can be divide for each component
  -- conversion time-integer must be divide by 1000 (PS resolution in module)
  -- https://groups.google.com/g/comp.lang.vhdl/c/-5j5310YpVY?pli=1
  constant C_MAIN_CLOCK_PERIOD : integer := 10;
  constant C_SPEED_GRADE       : string (1 to 5) := "sg701";
  constant C_TYPE              : string (1 to 6) := "NORMAL"; -- Denali

  -- Timing Parameters for speed group -701
  -- units in ns for all values
  --constant c_tCLK  : time   := 9.70 ns; -- Denali 103.95MHz
  constant c_tCLK  : time :=   9.62 ns; -- NORMAL 103.95MHz
  constant c_tAADV : time :=  70.00 ns;
  constant c_tACLK : time :=   7.00 ns;
  constant c_tAVH  : time :=   2.00 ns;
  constant c_AVH   : integer :=   2 / C_MAIN_CLOCK_PERIOD;
  constant c_tAVS  : time :=   5.00 ns;
  constant c_AVS   : integer :=   5 / C_MAIN_CLOCK_PERIOD;
  constant c_tAW   : time :=   0.00 ns;
  constant c_tBW   : time :=   0.00 ns;
  constant c_tCBPH : time :=   5.00 ns;
  constant c_tCEM  : time := 4000.0 ns;
  constant c_tCEW  : time :=    7.5 ns; -- tCEM MAX
  constant c_tCKA  : time :=  70.00 ns; -- ???
  constant c_tCO   : time :=  70.00 ns;
  constant c_tCW   : time :=  70.00 ns;
--  constant c_CW    : integer := time'pos(c_tCW) / 1000 / C_MAIN_CLOCK_PERIOD;
  constant c_CW    : integer := 1;
  constant c_tDH   : time :=   0.00 ns;
  constant c_tDW   : time :=  20.00 ns;
  constant c_tHZ   : time :=   8.00 ns;
  constant c_tOE   : time :=  20.00 ns;
  constant c_tOHZ  : time :=   8.00 ns;
  constant c_tPC   : time :=  20.00 ns;
--  constant c_tPU   : time := 150000 ns; -- Power-up delay 150us for real device
  constant c_tPU   : time := 150 ns; -- Power-up delay for simulation
--  constant c_PU    : integer := time'pos(c_tPU) / 1000 / C_MAIN_CLOCK_PERIOD;
  constant c_PU    : integer := 2;
  constant c_tRC   : time :=  70.00 ns;
  constant c_tVP   : time :=   5.00 ns;
  constant c_VP    : integer :=   5 / C_MAIN_CLOCK_PERIOD;
  constant c_tVPH  : time :=  10.00 ns;
--  constant c_VPH   : integer := time'pos(c_tVPH) / 1000 / C_MAIN_CLOCK_PERIOD;
  constant c_VPH   : integer := 1;
  constant c_tWC   : time :=  70.00 ns;
--  constant c_WC    : integer := time'pos(c_tWC) / 1000 / C_MAIN_CLOCK_PERIOD;
  constant c_WC    : integer := 1;
  constant c_tWP   : time :=  45.00 ns;
  constant c_tWPH  : time :=  10.00 ns;

  -- Timing Parameters for speed group -708
  -- units in ns for all values
--  constant c_tCLK  : time :=  12.50 ns; -- Denali and NORMAL period
--  constant c_tAADV : time :=  70.00 ns;
--  constant c_tACLK : time :=   9.00 ns;
--  constant c_tAVH  : time :=   2.00 ns;
--  constant c_tAVS  : time :=   5.00 ns;
--  constant c_tAW   : time :=  70.00 ns;
--  constant c_tBW   : time :=  70.00 ns;
--  constant c_tCBPH : time :=   6.00 ns;
--  constant c_tCEM  : time := 4000.0 ns;
--  constant c_tCEW  : time :=    7.5 ns; -- tCEM MAX
--  constant c_tCKA  : time :=  70.00 ns; -- ???
--  constant c_tCO   : time :=  70.00 ns;
--  constant c_tCW   : time :=  70.00 ns;
--  constant c_tDH   : time :=   0.00 ns;
--  constant c_tDW   : time :=  20.00 ns;
--  constant c_tHZ   : time :=   8.00 ns;
--  constant c_tOE   : time :=  20.00 ns;
--  constant c_tOHZ  : time :=   8.00 ns;
--  constant c_tPC   : time :=  20.00 ns;
--  constant c_tPU   : time := 150000 ns; -- Power-up delay 150us
--  constant c_tRC   : time :=  70.00 ns;
--  constant c_tVP   : time :=   5.00 ns;
--  constant c_tVPH  : time :=  10.00 ns;
--  constant c_tWC   : time :=  70.00 ns;
--  constant c_tWP   : time :=  45.00 ns;
--  constant c_tWPH  : time :=  10.00 ns;

  -- Timing Parameters for speed group -856
  -- units in ns for all values
--  constant c_tCLK  : time :=  15.00 ns; -- Denali and NORMAL period
--  constant c_tAADV : time :=  85.00 ns;
--  constant c_tACLK : time :=  11.00 ns;
--  constant c_tAVH  : time :=   2.00 ns;
--  constant c_tAVS  : time :=   5.00 ns;
--  constant c_tAW   : time :=  85.00 ns;
--  constant c_tBW   : time :=  85.00 ns;
--  constant c_tCBPH : time :=   8.00 ns;
--  constant c_tCEM  : time := 4000.0 ns;
--  constant c_tCEW  : time :=    7.5 ns; -- tCEM MAX
--  constant c_tCKA  : time :=  70.00 ns; -- ???
--  constant c_tCO   : time :=  85.00 ns;
--  constant c_tCW   : time :=  85.00 ns;
--  constant c_tDH   : time :=   0.00 ns;
--  constant c_tDW   : time :=  20.00 ns;
--  constant c_tHZ   : time :=   8.00 ns;
--  constant c_tOE   : time :=  20.00 ns;
--  constant c_tOHZ  : time :=   8.00 ns;
--  constant c_tPC   : time :=  25.00 ns;
--  constant c_tPU   : time := 150000 ns; -- Power-up delay 150us
--  constant c_tRC   : time :=  85.00 ns;
--  constant c_tVP   : time :=   7.00 ns;
--  constant c_tVPH  : time :=  10.00 ns;
--  constant c_tWC   : time :=  85.00 ns;
--  constant c_tWP   : time :=  55.00 ns;
--  constant c_tWPH  : time :=  10.00 ns;

  -- Size Parameters based on Part Width
  constant c_addr_bits : integer := 23;
  constant c_data_bits : integer := 16;
  constant c_mem_sizes : integer := 8388608;

end package micron_mem_parameters;

package body micron_mem_parameters is
end package body micron_mem_parameters;
