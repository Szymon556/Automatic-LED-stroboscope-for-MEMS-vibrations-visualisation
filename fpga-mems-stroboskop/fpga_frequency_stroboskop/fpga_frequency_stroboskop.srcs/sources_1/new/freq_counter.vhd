library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;


entity freq_counter is
    Generic(
    INTEGER_BITS_DATA : integer := 8;
    FRACTION_BITS_DATA : integer := -10
    );
    Port ( 
        clk : in std_logic;
        reset : in std_logic;
        sig : in std_logic;
        CE : in std_logic;
        start : in std_logic;
        data_out : out sfixed(INTEGER_BITS_DATA - 1 downto FRACTION_BITS_DATA)
       
    );
end freq_counter;

architecture Behavioral of freq_counter is
    subtype data_type is sfixed(INTEGER_BITS_DATA - 1 downto FRACTION_BITS_DATA);
    type state_type is (idle,reset_register,counting,done);
    
    constant one : data_type := to_sfixed(1,data_type'high,data_type'low);
    
    signal state_reg, state_next : state_type;
    signal sig_reg : std_logic;
    signal change_reg : std_logic;
    signal counter_reg,counter_next : data_type;
    signal output_reg, output_next : data_type;
    
begin
    
    process(clk,reset)
    begin
        if(reset = '1') then
            counter_reg <= (others => '0');
            sig_reg <= '0';
            state_reg <= idle;
            output_reg <= (others => '0');
        else
            if (clk'event and clk = '1') then
                state_reg <= state_next;
                counter_reg <= counter_next;
                output_reg <= output_next;
                sig_reg <= sig;
            end if;
        end if;
    end process;
    
    change_reg <= '1' when sig_reg = '0' and sig = '1' else '0';
    
    process(all)
    begin
        state_next <= state_reg;
        counter_next <= counter_reg;
        output_next <= output_reg;
        case state_reg is
            when idle =>
                if(start = '1') then
                    state_next <= reset_register;
                end if;
            when reset_register =>
                counter_next <= (others => '0');
                state_next <= counting;
            when counting =>
                if(CE = '1') then
                    state_next <= done;
                else
                    if(change_reg = '1') then
                        counter_next <= resize(one + counter_reg,counter_reg);            
                    end if;
                end if;
            when done =>
                output_next <= counter_reg;
                state_next <= idle;
            end case;
    end process;
        
     data_out <= counter_reg;
end Behavioral;