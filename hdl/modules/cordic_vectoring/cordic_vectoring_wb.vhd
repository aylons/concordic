-------------------------------------------------------------------------------
-- Title      : Wishbonized vectoring CORDIC
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cordic_vectoring_wb.vhd
-- Author     : aylons  <aylons@LNLS190>
-- Company    : 
-- Created    : 2014-09-03
-- Last update: 2014-10-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbonized version of the CORDIC in vectoring mode. This
-- module is transparent for both TGD and ADR, but to reduce area use, it may
-- me set to only accept a maximum number of simultaneous data points being
-- calculated. It may also accept parallel or serial I/Q data.
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-09-03  1.0      aylons  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.genram_pkg.all;
use work.wb_stream_pkg.all;

-------------------------------------------------------------------------------

-- Input data structure:
-- I = (g_width*2)-1 downto g_width
-- Q = g_width-1 downto 0;
-- Output data structure:
-- mag = (g_width*2)-1 downto g_width
-- phase  = g_width-1 downto 0

entity cordic_vectoring_wb is

  generic (
    g_stages       : natural := 32;
    g_width        : natural := 32;
    g_simultaneous : natural := 4;
    g_parallel     : boolean := true;

    g_tgd_width     : natural := 4;
    g_adr_width     : natural := 3;
    g_input_buffer  : natural := 4;
    g_output_buffer : natural := 2
    );

  port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;
    ce_i  : in  std_logic;
    snk_i : in  t_wbs_sink_in;
    snk_o : out t_wbs_sink_out;
    src_i : in  t_wbs_source_in;
    src_o : out t_wbs_source_out
    );

end entity cordic_vectoring_wb;

-------------------------------------------------------------------------------

architecture str of cordic_vectoring_wb is

  signal data_sink, data_source         : std_logic_vector(g_width*2-1 downto 0) := (others => '0');
  signal metadata_sink, metadata_source : std_logic_vector(g_tgd_width + g_adr_width - 1 downto 0);
  signal I                              : std_logic_vector(g_width-1 downto 0)   := (others => '0');
  signal Q                              : std_logic_vector(g_width-1 downto 0)   := (others => '0');
  signal mag                            : std_logic_vector(g_width-1 downto 0)   := (others => '0');
  signal phase                          : std_logic_vector(g_width-1 downto 0)   := (others => '0');

  signal tgd_sink   : std_logic_vector(g_tgd_width-1 downto 0) := (others => '0');
  signal adr_sink   : std_logic_vector(g_adr_width-1 downto 0) := (others => '0');
  signal valid_sink : std_logic                                := '0';

  signal tgd_source   : std_logic_vector(g_tgd_width-1 downto 0) := (others => '0');
  signal adr_source   : std_logic_vector(g_adr_width-1 downto 0) := (others => '0');
  signal valid_source : std_logic                                := '0';

  signal source_req : std_logic;
  signal ack_sink   : std_logic;
  signal ack_source : std_logic;
  signal full_meta  : std_logic;

  signal rst_n : std_logic;
  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  component cordic_vectoring_slv is
    generic (
      g_stages : natural;
      g_width  : natural);
    port (
      x_i     : in  std_logic_vector(g_width-1 downto 0) := (others => '0');
      y_i     : in  std_logic_vector(g_width-1 downto 0) := (others => '0');
      clk_i   : in  std_logic;
      ce_i    : in  std_logic;
      valid_i : in  std_logic;
      rst_i   : in  std_logic;
      mag_o   : out std_logic_vector(g_width-1 downto 0) := (others => '0');
      phase_o : out std_logic_vector(g_width-1 downto 0) := (others => '0');
      valid_o : out std_logic);
  end component cordic_vectoring_slv;

  component decoupled_fifo is
    generic (
      g_fifo_width : natural;
      g_fifo_depth : natural);
    port (
      rst_n_i : in  std_logic;
      clk_i   : in  std_logic;
      d_i     : in  std_logic_vector(g_fifo_width-1 downto 0);
      we_i    : in  std_logic;
      rd_i    : in  std_logic;
      full_o  : out std_logic;
      d_o     : out std_logic_vector(g_fifo_width-1 downto 0);
      valid_o : out std_logic);
  end component decoupled_fifo;

  component generic_shiftreg_fifo is
    generic (
      g_data_width : integer;
      g_size       : integer);
    port (
      rst_n_i       : in  std_logic := '1';
      clk_i         : in  std_logic;
      d_i           : in  std_logic_vector(g_data_width-1 downto 0);
      we_i          : in  std_logic;
      q_o           : out std_logic_vector(g_data_width-1 downto 0);
      rd_i          : in  std_logic;
      full_o        : out std_logic;
      almost_full_o : out std_logic;
      q_valid_o     : out std_logic);
  end component generic_shiftreg_fifo;

  component xwb_stream_sink is
    generic (
      g_data_width   : natural;
      g_addr_width   : natural;
      g_tgd_width    : natural;
      g_buffer_depth : natural);
    port (
      clk_i    : in  std_logic;
      rst_n_i  : in  std_logic;
      snk_i    : in  t_wbs_sink_in;
      snk_o    : out t_wbs_sink_out;
      addr_o   : out std_logic_vector(g_adr_width-1 downto 0);
      data_o   : out std_logic_vector(g_data_width-1 downto 0);
      tgd_o    : out std_logic_vector(g_tgd_width-1 downto 0);
      error_o  : out std_logic;
      dvalid_o : out std_logic;
      dreq_i   : in  std_logic);
  end component xwb_stream_sink;

  component xwb_stream_source is
    generic (
      g_data_width   : natural;
      g_addr_width   : natural;
      g_tgd_width    : natural;
      g_buffer_depth : natural);
    port (
      clk_i    : in  std_logic;
      rst_n_i  : in  std_logic;
      src_i    : in  t_wbs_source_in;
      src_o    : out t_wbs_source_out;
      addr_i   : in  std_logic_vector(g_adr_width-1 downto 0);
      data_i   : in  std_logic_vector(g_data_width-1 downto 0);
      tgd_i    : in  std_logic_vector(g_tgd_width-1 downto 0);
      dvalid_i : in  std_logic;
      error_i  : in  std_logic;
      dreq_o   : out std_logic);
  end component xwb_stream_source;
  
begin  -- architecture str

  rst_n <= not(rst_i);

  cmp_wb_sink : xwb_stream_sink
    generic map (
      g_data_width   => g_width*2,
      g_addr_width   => g_adr_width,
      g_tgd_width    => g_tgd_width,
      g_buffer_depth => g_input_buffer)
    port map (
      clk_i    => clk_i,
      rst_n_i  => rst_n,
      snk_i    => snk_i,
      snk_o    => snk_o,
      addr_o   => adr_sink,
      data_o   => data_sink,
      tgd_o    => tgd_sink,
      error_o  => open,                 -- no error treatment
      dvalid_o => valid_sink,
      dreq_i   => ack_sink);

  I <= data_sink(g_width*2-1 downto g_width);
  Q <= data_sink(g_width-1 downto 0);

  cmp_cordic : cordic_vectoring_slv
    generic map (
      g_stages => g_stages,
      g_width  => g_width)
    port map (
      x_i     => I,
      y_i     => Q,
      clk_i   => clk_i,
      ce_i    => ce_i,
      valid_i => ack_sink,
      rst_i   => rst_i,
      mag_o   => mag,
      phase_o => phase,
      valid_o => valid_source);

  data_source(g_width*2-1 downto g_width) <= mag;
  data_source(g_width-1 downto 0)         <= phase;

  -- Metadata
  metadata_sink <= tgd_sink & adr_sink;
  ack_sink      <= not(full_meta) and ce_i and valid_sink;
  ack_source    <= soruce_req and ce_i and valid_source;
  -- Stop accepting new data if full

  cmp_metadata : decoupled_fifo
    generic map(
      g_fifo_width => g_adr_width + g_tgd_width,
      g_fifo_depth => g_simultaneous)
    port map (
      rst_n_i => rst_n,
      clk_i   => clk_i,
      d_i     => metadata_sink,
      we_i    => ack_sink,
      rd_i    => ack_source,
      d_o     => metadata_source,
      full_o  => full_meta);

  tgd_source <= metadata_source(g_tgd_width + g_adr_width - 1 downto g_adr_width);
  adr_source <= metadata_source(g_adr_width - 1 downto 0);

  cmp_wb_source : xwb_stream_source
    generic map (
      g_data_width   => g_width*2,
      g_addr_width   => g_adr_width,
      g_tgd_width    => g_tgd_width,
      g_buffer_depth => g_output_buffer)
    port map (
      clk_i    => clk_i,
      rst_n_i  => rst_n,
      src_i    => src_i,
      src_o    => src_o,
      addr_i   => adr_source,
      data_i   => data_source,
      tgd_i    => tgd_source,
      dvalid_i => ack_source,
      error_i  => '0',                  --error is only forwarded through TGD
      dreq_o   => source_req);

end architecture str;

-------------------------------------------------------------------------------
