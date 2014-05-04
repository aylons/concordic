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

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

begin  -- architecture str

  --TODO: for now, it only generates a rect_to_polar CORDIC. Adapt so we can
  --generate other algorithms while reusing as much code as possible, so it
  --will be easy to maintain and evolve - hardware is already hard enough.

  
  
end architecture str;

-------------------------------------------------------------------------------
