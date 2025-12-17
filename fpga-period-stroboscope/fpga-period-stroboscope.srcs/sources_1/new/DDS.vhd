

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;

use IEEE.NUMERIC_STD.ALL;
entity DDS is
  Generic(
   -- Rozmiar danych wejściowych
    INTEGER_PART_INPUT : integer := 22;
    FRACTION_PART_INPUT : integer := 0;
    -- Rozmiar danych 
    INTEGER_PART_PHASE : integer := 34;
    FRACTION_PART_PHASE : integer := 0
  );
  Port ( 
    clk : in std_logic;
    reset : in  std_logic;
    data_in : in ufixed(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT);
    -- Sygnały odpowiedzialne za kontrole odbioru danych
    i_stb : in std_logic;
    o_busy : out std_logic; 
    -- Sygnał odpowiedzialny za uruchomienie LED_CONTROLLER
    start_sig : out std_logic
  );
end DDS;

architecture Behavioral of DDS is
   
    -- Dane odbierane i buforowane
    subtype input_t is ufixed(INTEGER_PART_INPUT - 1  downto FRACTION_PART_INPUT);
  
    -- Dane wyjściowe oraz sterujęce generacją sygnału na wyjściu DDS
    subtype data_t is ufixed(INTEGER_PART_PHASE - 1  downto FRACTION_PART_PHASE);
    
   
     
    -- Dekalracja stałych
    constant multiplier : data_t := to_ufixed(43, data_t'high, data_t'low);  -- (2^32 / 10^8 )
    constant offset : data_t := to_ufixed(43, data_t'high, data_t'low); -- (2^32 * X) / 10^8

    -- Dekalracja stanów FSMD
    type state_type  is (idle,step_calc,add_offset,strobe);
    
    -- rejestry maszyny stanów
    signal state_reg, state_next : state_type;
    signal buff_data : input_t;
    signal step_reg, step_next : data_t;
    signal phase_reg,phase_next : data_t;
    signal output_reg, output_next : data_t;
    signal done_reg, done_next : std_logic;
    

   
    -- Sygnał odpowiedzialny za uruchomienie maszyny stanów
   signal start_reg, start_next : std_logic;
  
   
    
begin
    
    -- Proces odpowidzialny za komunikacje z Master/Slave oraz maszynę stanów
    process(clk,reset)
    begin
        if(reset = '1') then
            state_reg <= idle;
            buff_data <= (others => '0');
            step_reg <= (others => '0');
            phase_reg <= (others => '0');
            output_reg <= (others => '0');
            done_reg <= '0';
            start_reg <= '0'; 
            o_busy <= '0';
         else
            if(rising_edge(clk)) then
                state_reg <= state_next;
                phase_reg <= phase_next;
                done_reg <= done_next;
                output_reg <= output_next;
                step_reg <= step_next;
                start_reg <= start_next;
                if((not o_busy) and (i_stb)) then 
                         o_busy <= '1';
                         start_reg <= '1';
                         buff_data <= resize(data_in, input_t'high,input_t'low);        
                elsif(done_reg = '1') then
                    o_busy <= '0';
                elsif(state_reg = strobe) then
                   o_busy <= '1';  
            end if;
            end if;
        end if;
    end process;
    
-- FSMD
process(all)
begin
    state_next <= state_reg;
    step_next <= step_reg;
    phase_next <= phase_reg;
    output_next <= output_reg;
    done_next <= done_reg;
    start_next <= start_reg;
    case state_reg is
        when idle =>
            phase_next <= (others => '0');
            done_next <= '0';
            if(start_reg = '1') then
               state_next <= step_calc;
             end if;
        when step_calc =>
            step_next <= resize(buff_data * multiplier, data_t'high, data_t'low); -- Buff_data to moje HZ
            state_next <= add_offset;
        when add_offset =>
            step_next <= resize(step_reg + offset, data_t'high, data_t'low);
            state_next <= strobe;
        when strobe =>
            phase_next <= resize(phase_reg + step_reg, data_t'high, data_t'low,fixed_wrap,fixed_truncate);
            if(phase_reg(phase_reg'high) = '1' and phase_next(phase_reg'low) = '0') then 
                done_next <= '1';
                state_next <= idle;     
            end if;

    end case;
end process;

start_sig <= done_reg;

end Behavioral;