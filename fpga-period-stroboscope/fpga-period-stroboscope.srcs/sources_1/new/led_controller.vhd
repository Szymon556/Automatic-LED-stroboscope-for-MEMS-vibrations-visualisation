library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;

use IEEE.NUMERIC_STD.ALL;



entity led_controler is
     Generic(
        INTEGER_PART : integer := 22;
        FRACTION_PART : integer := 0
    );
    Port ( 
        clk : in std_logic;
        reset : in std_logic;
        start_sig : in  std_logic;
        input_data : in ufixed( INTEGER_PART - 1 downto FRACTION_PART);
        led_flash : out std_logic
       
    );
end led_controler;

architecture Behavioral of led_controler is
    subtype data_path is ufixed(INTEGER_PART - 1 downto FRACTION_PART);
    -- Przez ile procent czasu świecimy
    constant flash_period : ufixed(0 downto -22) := to_ufixed(0.1, 0, -22);
    constant one : data_path := to_ufixed(1,data_path'high,data_path'low);
    -- Obsługa maszyny stanów
    type state_type is (idle,store_data,flash); 
    signal state_reg, state_next : state_type;
    signal counter_reg, counter_next : data_path;
    signal led_strobe : std_logic := '0';
    signal buff_data : data_path;
   
    
begin
    
  
 
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg   <= idle;
            counter_reg <= (others => '0');
            buff_data <= (others => '0');
        elsif rising_edge(clk) then
            counter_reg <= counter_next;
            state_reg <= state_next;
            buff_data <= resize(input_data,data_path'high, data_path'low);
        end if;
    end process;
    
process(all)
    begin
        state_next <= state_reg;
        counter_next <= counter_reg;
        led_strobe <= '0';
        case state_reg is
            when idle =>
                counter_next <= (others => '0');
                if start_sig = '1' then
                    state_next <= store_data;
                end if;
            when store_data => 
                counter_next <= resize(buff_data * flash_period, data_path'high, data_path'low);
                state_next <= flash;   
            when flash =>
                if(counter_reg = one) then
                    state_next <= idle;
                 else
                    led_strobe <= '1';
                    counter_next <= resize(counter_reg - one ,data_path'high , data_path'low, fixed_wrap, fixed_truncate ); 
                end if;     
        end case;
    end process;
    led_flash <= led_strobe;
end Behavioral;