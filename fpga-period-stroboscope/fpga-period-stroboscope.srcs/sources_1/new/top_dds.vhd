----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/31/2025 03:11:50 PM
-- Design Name: 
-- Module Name: top_dds - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;

entity top_dds is
          Generic(
       -- Rozmiar danych wejściowych 
        INTEGER_PART_INPUT : integer := 22;
        FRACTION_PART_INPUT : integer := 0;
        -- Rozmiar danych 
        INTEGER_PART_PHASE : integer := 32;
        FRACTION_PART_PHASE : integer := 0
      );
      Port ( 
          clk : in std_logic;
          reset : in  std_logic;
          frequency : in ufixed(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT);
          period : in ufixed(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT); 
          -- Sygnały odpowiedzialne za kontrole odbioru danych
          i_stb : in std_logic;
          o_busy : out std_logic;
          strobe : out std_logic
          );
end top_dds;

architecture Behavioral of top_dds is
    signal start_sig : std_logic;  
begin
    
    DDS: entity work.DDS(Behavioral)
        generic map(INTEGER_PART_INPUT, FRACTION_PART_INPUT,
        INTEGER_PART_PHASE,FRACTION_PART_PHASE)
        port map(clk => clk, reset => reset, data_in => frequency, i_stb => i_stb, o_busy => o_busy, start_sig => start_sig);
        
    LED_CONTROLER : entity work.LED_CONTROLER(Behavioral)
        generic map(INTEGER_PART_INPUT, FRACTION_PART_INPUT)
        port map(clk => clk, reset => reset, start_sig => start_sig, input_data => period, led_flash => strobe);

end Behavioral;