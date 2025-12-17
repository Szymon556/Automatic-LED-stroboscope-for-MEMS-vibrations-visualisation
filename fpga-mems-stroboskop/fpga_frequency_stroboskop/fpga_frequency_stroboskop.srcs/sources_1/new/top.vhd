library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;
entity top is
    Generic(
    -- Opóźnienie dla Debouncera
    DEBOUNCE_TIME : integer := 4;
    -- Rozmiar danych wychodzących z licznika częstotliwości
    -- oraz rozmiar danych dla wejścia dla LED_Controller
    -- max 18 bitów inaczej może być problem z wykorzystaniem DSP.(DSP na 18 x 25)
    INTEGER_BITS_DATA: integer := 18;
    FRACTION_BITS_DATA : integer := 0;
    -- Rozmiar danych dla filtra, po przesunięciu 
    INTEGER_BITS_FILTER: integer := 2;
    FRACTION_BITS_FILTER : integer := -16;
    -- Wielkość rejestru generatora fazy
    INTEGER_BITS_PHASE : integer := 32; 
    FRACTION_BITS_PHASE : integer := 0
  
    );
    Port ( 
    clk : in std_logic;
    reset : in std_logic;
    start : in std_logic;
    sig : in std_logic;
    LED_sig: out std_logic;
    start_filter_1 :in std_logic;
    start_filter_2 : in std_logic;
    start_filter_3 : in std_logic

    );
end top;

architecture Behavioral of top is
    
    -- stałe do normalizacji wartośći WE\WY z filtra
    --======================================--
    -- Żeby filtr poprawnie działał, dane   --
    -- wejściowe muszę być tak przesunięte  --
    -- żeby pierwsza liczba znacząca była   --
    -- dwa miejsca po przecinku.Dla większ- --
    -- ych wartośći filtr będzie się prze-  --
    -- pełniał.                             --
    --======================================--
    constant left : sfixed(24 downto 0) := to_sfixed(65536, 24,0); -- jeżeli mamy okres 1ms dla CE to powinno być 128 x 1000 (dla 10^4 było 1024)
    constant right : sfixed(1 downto -23) := to_sfixed(0.000015259, 1,-23);
    
    signal CE : std_logic;
    signal frequency : sfixed(INTEGER_BITS_DATA - 1 downto FRACTION_BITS_DATA);
    signal filter_input : sfixed(INTEGER_BITS_FILTER - 1 downto FRACTION_BITS_FILTER);
    signal filter_output : sfixed(INTEGER_BITS_FILTER - 1 downto FRACTION_BITS_FILTER);
    signal filter_output_2 : sfixed(INTEGER_BITS_FILTER - 1 downto FRACTION_BITS_FILTER);
    signal filter_output_3 : sfixed(INTEGER_BITS_FILTER - 1 downto FRACTION_BITS_FILTER);
    signal db_sig : std_logic;
    signal DDS_data : std_logic_vector(INTEGER_BITS_DATA - 1 downto FRACTION_BITS_DATA):= (others => '0');
    signal start_filter_1_reg : std_logic;
    signal start_filter_2_reg : std_logic;
    signal start_filter_3_reg : std_logic;
begin
   
  process(start_filter_1, start_filter_2, start_filter_3)
    begin
        start_filter_1_reg <= '0';
        start_filter_2_reg <= '0';
        start_filter_3_reg <= '0';
    
        if start_filter_1 = '1' then
            start_filter_1_reg <= start_filter_1;
        elsif start_filter_2 = '1' then
            start_filter_2_reg <= start_filter_2;
        elsif start_filter_3 = '1' then
            start_filter_3_reg <= start_filter_3;
        end if;
    end process; 
    
    DEBOUNCER : entity work.debouncer(Behavioral)
                Generic map(
                DEBOUNCE_TIME
                )
                port map(clk => clk, reset => reset, sw => sig, db => db_sig);
     
    
    FREQ_COUNTER : entity work.freq_counter(Behavioral)
                   generic map(
                   INTEGER_BITS_DATA,
                   FRACTION_BITS_DATA
                   )
                   port map(clk => clk, reset => reset, start => start,sig => db_sig, CE => CE, data_out => frequency);
               
    TRIGGER_COUNTER : entity work.trigger_counter(Behavioral)
                      port map(clk => clk, reset => reset, output => CE, start => start);
                      
   filter_input <= resize(frequency * right,filter_input'high, filter_input'low);   
                   
    FILTR_1 : entity work.filtr_1(Behavioral)
               port map(clk => clk, reset => reset, start => start_filter_1_reg, strobe => CE, Xn => filter_input,Yn => filter_output);
               
    
    FILTR_2 : entity work.filtr_2(Behavioral)
               port map(clk => clk, reset => reset, strobe => CE,start => start_filter_2_reg, Xn => filter_input,Yn => filter_output_2);
               
    FILTR_3 : entity work.filtr_3(Behavioral)
               port map(clk => clk, reset => reset, strobe => CE, start => start_filter_3_reg, Xn => filter_input,Yn => filter_output_3);           
               
   DDS_data <= to_slv(resize(filter_output * left,DDS_data'high, DDS_data'low)) when start_filter_1 = '1' else 
               to_slv(resize(filter_output_2 * left,DDS_data'high, DDS_data'low)) when start_filter_2 = '1' else
               to_slv(resize(filter_output_3 * left,DDS_data'high, DDS_data'low)) when start_filter_3 = '1' else
               (others => '0');
                         
  TOP_DDS : entity work.top_dds(Behavioral)
            generic map(
                INTEGER_BITS_DATA,
                FRACTION_BITS_DATA,
                INTEGER_BITS_PHASE,
                FRACTION_BITS_PHASE
             )
             port map(clk => clk, reset => reset, frequency => DDS_data, period => DDS_data, CE => CE, strobe => LED_sig);

    
 end Behavioral;


