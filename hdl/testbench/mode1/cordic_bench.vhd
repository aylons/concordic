-------------------------------------------------------------------------------
-- Title      : Testbench for CORDIC module
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cordic_bench.vhd
-- Author     : aylons  <aylons@LNLS190>
-- Company    : 
-- Created    : 2014-03-21
-- Last update: 2014-05-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-03-21  1.0      aylons  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity cordic_bench is
end entity cordic_bench;


architecture test of cordic_bench is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  constant c_input_freq      : real    := 100.0e6;
  constant c_clock_period    : time    := 1.0 sec /(2.0*c_input_freq);
  constant c_cycles_to_reset : natural := 4;

  signal clock   : std_logic := '0';
  signal reset_n : std_logic := '0';

  constant c_width        : natural := 32;
  constant c_stages       : natural := 32;
  constant c_cordic_delay : natural := c_stages+1;

  signal I_in : std_logic_vector(c_width-1 downto 0) := (others => '0');
  signal Q_in : std_logic_vector(c_width-1 downto 0) := (others => '0');

  signal mag_out   : std_logic_vector(c_width-1 downto 0);
  signal phase_out : std_logic_vector(c_width-1 downto 0);

  signal endoffile : std_logic := '0';


  component cordic_vectoring_slv is
    generic (
      g_stages : natural;
      g_width  : natural);
    port (
      x_i     : in  std_logic_vector(g_width-1 downto 0);
      y_i     : in  std_logic_vector(g_width-1 downto 0);
      clk_i   : in  std_logic;
      ce_i    : in  std_logic;
      mag_o   : out std_logic_vector(g_width-1 downto 0);
      phase_o : out std_logic_vector(g_width-1 downto 0));
  end component cordic_vectoring_slv;

begin

  clk_gen : process
  begin
    clock <= '0';
    wait for c_clock_period;
    clock <= '1';
    wait for c_clock_period;
  end process;


  rst_gen : process(clock)
    variable clock_count : natural := c_cycles_to_reset;
  begin
    if rising_edge(clock) and clock_count /= 0 then
      clock_count := clock_count - 1;

      if clock_count = 0 then
        reset_n <= '1';
      end if;

    end if;
  end process;

  uut: cordic_vectoring_slv
    generic map (
      g_stages => c_stages,
      g_width  => c_width)
    port map (
      x_i     => I_in,
      y_i     => Q_in,
      clk_i   => clock,
      ce_i    => '1',
      mag_o   => mag_out,
      phase_o => phase_out);

  sample_read : process(clock)
    file vect_file            : text open read_mode is "vectoring_in.dat";
    variable cur_line         : line;
    variable datain1, datain2 : real;
  begin
    if rising_edge(clock) then
      --Pick samples for vectoring mode
      if not endfile(vect_file) then
        readline(vect_file, cur_line);

        read(cur_line, datain1);
        I_in <= std_logic_vector(to_signed(integer(datain1*(2.0**(c_width-1))), c_width));

        read(cur_line, datain2);
        Q_in <= std_logic_vector(to_signed(integer(datain2*(2.0**(c_width-1))), c_width));
        
      else
        endoffile <= '1';
      end if;
    end if;  -- rising_edge
  end process sample_read;


  signal_write : process(clock)
    file vect_file      : text open write_mode is "vectoring_out.dat";
    variable cur_line   : line;
    variable mag, phase : integer;
--    variable counter    : natural = cordic_delay;
  begin
    if rising_edge(clock) then
      if(endoffile = '0') then
        mag := to_integer(unsigned(mag_out));
        write(cur_line, mag);

        write(cur_line, string'(" "));

        phase := to_integer(signed(phase_out));
        write(cur_line, phase);

        writeline(vect_file, cur_line);
      else
        assert (false) report "Input file finished." severity failure;
      end if;
    end if;
  end process signal_write;
  
end architecture test;
