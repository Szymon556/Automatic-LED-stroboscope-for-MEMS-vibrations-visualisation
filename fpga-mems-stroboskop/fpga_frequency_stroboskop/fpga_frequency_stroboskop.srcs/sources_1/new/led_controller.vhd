library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;
use IEEE.NUMERIC_STD.ALL;



entity led_controler is
     Generic(
        INTEGER_PART : integer := 24;
        FRACTION_PART : integer := 0
    );
    Port ( 
        clk : in std_logic;
        reset : in std_logic;
        start_sig : in  std_logic;
        input_data : in ufixed( INTEGER_PART - 1 downto FRACTION_PART);
        strobe : out std_logic
       
    );
end led_controler;

architecture Behavioral of led_controler is
    subtype data_path is ufixed(INTEGER_PART - 1 downto FRACTION_PART);
    -- Przez ile procent czasu świecimy
    constant flash_period : ufixed(0 downto -22) := to_ufixed(0.01, 0, -22);
    constant one : data_path := to_ufixed(1,data_path'high,data_path'low);
    constant norm : data_path := to_ufixed(1000,data_path'high,data_path'low);
    -- Obsługa maszyny stanów
    type state_type is (idle,normalization,store_data,flash); 
    signal state_reg, state_next : state_type;
    signal counter_reg, counter_next : data_path;
    signal done_reg, done_next : std_logic;
    -- świecenie LED
    signal flash_sig, flash_next: std_logic;
    signal buff_data : data_path;
   
    
begin
    
  
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg   <= idle;
            counter_reg <= (others => '0');
            buff_data <= (others => '0');
            flash_sig <= '0';
        elsif rising_edge(clk) then
            counter_reg <= counter_next;
            done_reg <= done_next;
            state_reg <= state_next;
            buff_data <= resize(input_data,data_path'high, data_path'low);
            flash_sig <= flash_next;
        end if;
    end process;
    
process(all)
    begin
        state_next <= state_reg;
        counter_next <= counter_reg;
        done_next <= done_reg;
        flash_next <= flash_sig;
        case state_reg is
            when idle =>
                counter_next <= (others => '0');
                done_next <= '0';
                flash_next <= '0';
                if start_sig = '1' then
                    state_next <= normalization;
                end if;
            when normalization =>
                counter_next <= resize(buff_data * norm,data_path'high , data_path'low);
                state_next <= store_data;
            when store_data => 
                counter_next <= resize(counter_reg * flash_period, data_path'high, data_path'low);
                state_next <= flash;   
            when flash =>
                flash_next <= '1';
                if(counter_reg = one) then
                    state_next <= idle;
                    done_next <= '1';
                 else
                    counter_next <= resize(counter_reg - one ,data_path'high , data_path'low, fixed_wrap, fixed_truncate ); 
                end if;     
        end case;
    end process;
    strobe <= flash_sig;
end Behavioral;