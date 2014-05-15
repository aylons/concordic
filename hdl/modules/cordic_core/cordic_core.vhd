-------------------------------------------------------------------------------
-- Title      : Configurable Cordic core
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cordic_core.vhd
-- Author     : Aylons  <aylons@aylons-yoga2>
-- Company    : 
-- Created    : 2014-05-03
-- Last update: 2014-05-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This CORDIC allow configuration of its number of stages and
-- accepts any bus size for its inputs and ouputs. The calculation to be done
-- is defined by a generic value, and there's no need for external codes due to
-- any parameter change.
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
-- Copyright (c) 2014 Aylons Hazzud
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-03  1.0      aylons  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-------------------------------------------------------------------------------

entity cordic_core is

  generic (
    g_stages : natural := 20;
    g_mode   : string  := "rect_to_polar"
    );

  -- x represents the x axis in rectangular coordinates or amplitude in polar
  -- y represents the y axis in rectangular coordinates
  -- z represents phase in polar coordinates
  port (
    x_i   : in  signed;
    y_i   : in  signed;
    z_i   : in  signed;
    clk_i : in  std_logic;
    ce_i  : in  std_logic;
    x_o   : out signed;
    y_o   : out signed;
    z_o   : out signed
    );

end entity cordic_core;

-------------------------------------------------------------------------------

architecture str of cordic_core is
  constant c_width : natural := x_i'length+1;
  type wiring is array (0 to g_stages) of signed(c_width-1 downto 0);
  type control_wiring is array (0 to g_stages) of boolean;

  signal x_inter : wiring;
  signal y_inter : wiring;
  signal z_inter : wiring;

  signal x_shifted : wiring;
  signal y_shifted : wiring;

  signal control_x : control_wiring;
  signal control_y : control_wiring;

  component addsub is
    port (
      a_i      : in  signed;
      b_i      : in  signed;
      sub_i    : in  boolean;
      clk_i    : in  std_logic;
      ce_i     : in  std_logic;
      result_o : out signed);
  end component addsub;

  function stage_constant(mode, stage, width : natural) return signed is
    variable const_vector : signed(width-1 downto 0);
  begin
    -- Each iteration must sum or subtract arctg(1/(2^(stage-1)))
    -- only work for cordics up to 32 bit
    const_vector := to_signed(integer(arctan(2.0**(real(1-stage)))/(MATH_2_PI)*(2.0**real(width))), width);
    return const_vector;
  end function;

begin  -- architecture str

  --TODO: for now, it only generates a rect_to_polar CORDIC. Adapt so we can
  --generate other algorithms while reusing as much code as possible, so it
  --will be easy to maintain and evolve - hardware is already hard enough.

  x_inter(0) <= x_i(x_i'left) & x_i;
  y_inter(0) <= y_i(y_i'left) & y_i;
  z_inter(0) <= z_i & "0";


  CORE_STAGES : for stage in 1 to g_stages generate

    control_x(stage) <= (y_inter(stage-1) < 0);
    control_y(stage) <= not(control_x(stage));

    x_shifted(stage) <= shift_right(x_inter(stage-1), stage-1);
    y_shifted(stage) <= shift_right(y_inter(stage-1), stage-1);

    cmp_x_stage : addsub
      port map(
        a_i      => x_inter(stage-1),
        b_i      => y_shifted(stage),
        sub_i    => control_x(stage),
        clk_i    => clk_i,
        ce_i     => ce_i,
        result_o => x_inter(stage));

    cmp_y_stage : addsub
      port map(
        a_i      => y_inter(stage-1),
        b_i      => x_shifted(stage),
        sub_i    => control_y(stage),
        clk_i    => clk_i,
        ce_i     => ce_i,
        result_o => y_inter(stage));

    cmp_z_stage : addsub
      port map (
        a_i      => z_inter(stage-1),
        b_i      => stage_constant(1, stage, c_width),
        sub_i    => control_x(stage),
        clk_i    => clk_i,
        ce_i     => ce_i,
        result_o => z_inter(stage));
  end generate;

  --TODO: Round the output
  x_o <= x_inter(g_stages)(c_width-1 downto 1);
  y_o <= y_inter(g_stages)(c_width-1 downto 1);
  z_o <= z_inter(g_stages)(c_width-1 downto 1);
  
end architecture str;
