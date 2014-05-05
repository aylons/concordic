-------------------------------------------------------------------------------
-- Title      : Unconstrained multiplier
-- Project    : 
-------------------------------------------------------------------------------
-- File       : unc_mult.vhd
-- Author     : Aylons  <concordic@aylons.com>
-- Company    : 
-- Created    : 2014-05-03
-- Last update: 2014-05-04
-- Platform   : 
-- Standard   : VHDL'93/02/08
-------------------------------------------------------------------------------
-- Description: Generic multiplier which accepts signed vectors of any size
-- for both inputs and the resulting output. The output width must be smaller
-- than the summed width of the inputs. For outputs smaller than a_width +
-- b_width - 1, there will be one sign bit followed by as results MSBs.
--
-- This multiplier expects the synthesizer to infer multiplier logic from the * operator.
-------------------------------------------------------------------------------
-- This file is part of Concordic.
--
-- Concordic is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Concordic is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Foobar. If not, see <http://www.gnu.org/licenses/>.
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-03  1.0      aylons  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unc_mult is
  port(
    a_i      : in  signed;
    b_i      : in  signed;
    result_o : out signed;
    clk_i    : in  std_logic);
end unc_mult;

architecture behavioural of unc_mult is

begin
  assert result_o'length < a_i'length + b_i'length
    report "result_o width bigger than summed widths of a_i and b_i"
    severity error;

  process(clk_i) is
    variable full_res : signed(a_i'length + b_i'length - 1 downto 0);
  begin
    if(rising_edge(clk_i)) then
      full_res := a_i * b_i;
      result_o <=  full_res(full_res'left-1 downto full_res'left-1-result_o'length);
    end if;
  end process;

end architecture behavioural;
