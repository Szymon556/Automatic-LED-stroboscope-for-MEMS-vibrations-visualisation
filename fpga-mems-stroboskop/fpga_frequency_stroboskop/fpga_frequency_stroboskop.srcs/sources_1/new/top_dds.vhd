
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
          frequency : in std_logic_vector(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT);
          period : in std_logic_vector(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT); 
          CE : in std_logic;
          strobe : out std_logic
          );
end top_dds;

architecture Behavioral of top_dds is
    signal start_sig : std_logic;  
begin
    
    DDS: entity work.DDS(Behavioral)
        generic map(
        INTEGER_PART_INPUT, 
        FRACTION_PART_INPUT,
        INTEGER_PART_PHASE,
        FRACTION_PART_PHASE
        )
        port map(clk => clk, reset => reset, data_in => frequency, CE => CE, start_sig => start_sig);
        
    LED_CONTROLER : entity work.LED_CONTROLER(Behavioral)
        generic map(
        INTEGER_PART_INPUT, 
        FRACTION_PART_INPUT
        )
        port map(clk => clk, reset => reset, start_sig => start_sig, input_data => to_ufixed(period,INTEGER_PART_INPUT - 1,FRACTION_PART_INPUT), strobe => strobe);
end Behavioral;