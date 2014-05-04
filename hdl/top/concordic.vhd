-------------------------------------------------------------------------------
-- Title      : Configurable Cordic
-- Project    : 
-------------------------------------------------------------------------------
-- File       : concordic.vhd
-- Author     : Aylons  <aylons@aylons-yoga2>
-- Company    : 
-- Created    : 2014-05-03
-- Last update: 2014-05-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This CORDIC allow configuration of its number of stages and
-- accepts any bus size for its inputs and ouputs. The calculation to be done
-- is defined by a generic value, and there's no need for external codes due to
-- any parameter change.
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
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

entity concordic is

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
    x_o   : out signed;
    y_o   : out signed;
    z_o   : out signed
    );

end entity concordic;

-------------------------------------------------------------------------------

architecture str of concordic is
  type wiring is array (0 to g_stages) of signed(x_i'range);
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
      sel_i    : in  boolean;
      clk_i    : in  std_logic;
      result_o : out signed);
  end component addsub;

  function stage_constant(mode,stage, width : natural) return signed is
    variable const_vector : signed(width-1 downto 0);
  begin
    const_vector := to_signed(integer(arctan(2.0**(real(1-stage)))/(MATH_2_PI)*(2.0**real(width))), width);
    return const_vector;
  end function;
  
begin  -- architecture str

  x_inter(0) <= x_i;
  y_inter(0) <= y_i;
  z_inter(0) <= z_i;

  --TODO: for now, it only generates a rect_to_polar CORDIC. Adapt so we can
  --generate other algorithms while reusing as much code as possible, so it
  --will be easy to maintain and evolve - hardware is already hard enough.

  CORDIC_CORE : for stage in 1 to g_stages generate

    control_x(stage) <= (y_inter(stage-1) < 0);
    control_y(stage) <= not(control_x(stage));

    x_shifted(stage) <= shift_right(x_inter(stage-1), stage-1);
    y_shifted(stage) <= shift_right(y_inter(stage-1), stage-1);
    
    x_stage : addsub
      port map(
        a_i      => x_inter(stage-1),
        b_i      => y_shifted(stage),
        sel_i    => control_x(stage),
        clk_i    => clk_i,
        result_o => x_inter(stage));

    y_stage : addsub
      port map(
        a_i      => y_inter(stage-1),
        b_i      => x_shifted(stage),
        sel_i    => control_y(stage),
        clk_i    => clk_i,
        result_o => y_inter(stage));

    z_stage : addsub
      port map (
        a_i      => z_inter(stage-1),
        b_i      => stage_constant(1, stage, z_i'length),
        sel_i    => control_x(stage),
        clk_i    => clk_i,
        result_o => z_inter(stage));
  end generate;

  --TODO: Round the output
  x_o <= x_inter(g_stages);
  y_o <= y_inter(g_stages);
  z_o <= z_inter(g_stages);
  
end architecture str;
