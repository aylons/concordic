-------------------------------------------------------------------------------
-- Title      : Simple testbench
-- Project    : 
-------------------------------------------------------------------------------te
-- File       : simple_tb.vhd
-- Author     : Aylons  <aylons@aylons-yoga2>
-- Company    : 
-- Created    : 2014-05-04
-- Last update: 2014-05-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: SImplest testbench, just to see if code sinthesizes.
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
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-04  1.0      aylons  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity simple_tb is end entity simple_tb;

architecture test of simple_tb is

  constant c_clk_freq : real := 100.0e6;

  constant c_input_width  : natural := 24;
  constant c_output_width : natural := 24;

  constant c_number_of_stages : natural := 20;

  signal x_input : signed(c_input_width-1 downto 0) := x"010000";
  signal y_input : signed(c_input_width-1 downto 0) := x"010000";
  signal z_input : signed(c_input_width-1 downto 0) := x"000000";

  signal x_output : signed(c_output_width-1 downto 0);
  signal y_output : signed(c_output_width-1 downto 0);
  signal z_output : signed(c_output_width-1 downto 0);

  signal clk : std_logic := '0';

  -- Procedure for clock generation
  procedure clk_gen(signal clk : out std_logic; constant FREQ : real) is
    constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
  begin
    -- Check the arguments
    assert (HIGH_TIME /= 0 fs) report "clk_plain: High time is zero; time resolution to large for frequency" severity failure;
    -- Generate a clock cycle
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;

  component concordic is
    generic (
      g_stages : natural;
      g_mode   : string);
    port (
      x_i   : in  signed;
      y_i   : in  signed;
      z_i   : in  signed;
      clk_i : in  std_logic;
      x_o   : out signed;
      y_o   : out signed;
      z_o   : out signed);
  end component concordic;
  
begin

  clk_gen(clk, c_clk_freq);

  concordic_1 : entity work.concordic
    generic map (
      g_stages => c_number_of_stages,
      g_mode   => "rect_to_polar")
    port map (
      x_i   => x_input,
      y_i   => y_input,
      z_i   => z_input,
      clk_i => clk,
      x_o   => x_output,
      y_o   => y_output,
      z_o   => z_output);

end architecture test;
