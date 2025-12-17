

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;


entity top is
  Generic(
        -- Rozmiar danych 
        INTEGER_PART : integer := 22;
        FRACTION_PART: integer := 0
  );
  Port ( 
    clk : in std_logic;
    reset : in std_logic;
    sig : in std_logic;
    strobe : out std_logic
 

    
  );
end top;

architecture Behavioral of top is
    subtype data_path is ufixed(INTEGER_PART - 1 downto FRACTION_PART);
    -- Dodatkowe sygnały dla detectora
    signal i_busy_detector : std_logic;
    signal o_stb_detector : std_logic;
    signal period_reg : data_path;
    -- Dodatkowe sygnały dla Dividera
    signal i_busy_dds : std_logic;
    signal o_stb_dds : std_logic;
    signal freq_reg : data_path;
   
    signal db_sig : std_logic;
begin
    
    DEBOUNCER : entity work.debouncer(Behavioral)
                port map(clk => clk, reset => reset, sw => sig, db => db_sig );
    
    DETECTOR : entity work.detector(Behavioral)
                port map(clk => clk, reset => reset, level => db_sig, i_busy => i_busy_detector,
                o_stb => o_stb_detector, period => period_reg);
                
    DIVIDER : entity work.divider(Behavioral)
              port map(clk => clk, reset => reset, i_stb => o_stb_detector, o_busy => i_busy_detector,
              o_stb => o_stb_dds, i_busy => i_busy_dds, divisor => period_reg, output_data => freq_reg );
                          
    TOP_DDS : entity work.top_dds(Behavioral)            
              port map(clk => clk, reset => reset, frequency => freq_reg, period => period_reg, i_stb => o_stb_dds, o_busy => i_busy_dds,
              strobe => strobe);
   
 
   
end Behavioral;
