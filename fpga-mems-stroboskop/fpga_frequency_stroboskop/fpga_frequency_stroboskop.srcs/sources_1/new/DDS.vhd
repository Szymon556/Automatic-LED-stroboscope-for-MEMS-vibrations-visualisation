----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/17/2025 01:37:42 AM
-- Design Name: 
-- Module Name: DDS - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
    data_in : in std_logic_vector(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT);
    CE : in std_logic;
    -- Sygnał odpowiedzialny za uruchomienie LED_CONTROLLER
    start_sig : out std_logic
    --debug_output : out ufixed(INTEGER_PART_PHASE - 1 downto FRACTION_PART_PHASE)
  );
end DDS;

architecture Behavioral of DDS is
   
    -- Dane odbierane i buforowane
    subtype input_t is ufixed(INTEGER_PART_INPUT - 1  downto FRACTION_PART_INPUT);
  
    -- Dane wyjściowe oraz sterujęce generacją sygnału na wyjściu DDS
    subtype data_t is ufixed(INTEGER_PART_PHASE - 1  downto FRACTION_PART_PHASE);
    
   
     
    -- Dekalracja stałych
    constant multiplier : data_t := to_ufixed(43 , data_t'high, data_t'low);  -- (2^32 / 10^8 )
    constant offset : data_t := to_ufixed(43, data_t'high, data_t'low); -- (2^32 * X) / 10^8
    constant norm : data_t := to_ufixed(1000,  data_t'high, data_t'low); -- wartość przez którą trzeba pomnożyć Hz, zależy od CE

    
    
    -- Dekalracja stanów FSMD
    type state_type  is (IDLE,NORMALIZATION,STEP_CALC,ADD_OFFSET,STROBE);
    
    -- rejestry maszyny stanów
    signal state_reg, state_next : state_type;
    signal buff_reg, buff_next : input_t;
    signal step_reg, step_next : data_t;
    signal phase_reg,phase_next : data_t;
    signal output_reg, output_next : data_t;
    signal done_reg, done_next : std_logic;
    
   
    -- Sygnał odpowiedzialny za uruchomienie maszyny stanów
   signal start_reg, start_next : std_logic;
   signal start_dds : std_logic;
    
begin
    
    -- Proces odpowidzialny za komunikacje z Master/Slave oraz maszynę stanów
    process(clk,reset)
    begin
        if(reset = '1') then
            state_reg <= idle;
            buff_reg <= (others => '0');
            step_reg <= (others => '0');
            phase_reg <= (others => '0');
            output_reg <= (others => '0');
            done_reg <= '0';
            start_reg <= '0'; 
            start_dds <= '0';
         else
            if(rising_edge(clk)) then
                state_reg <= state_next;
                phase_reg <= phase_next;
                done_reg <= done_next;
                output_reg <= output_next;
                step_reg <= step_next;
                start_reg <= start_next;
                buff_reg <= buff_next;
                if(CE = '1') then
                    if(unsigned(data_in) > 8) then
                        start_dds <= '1';
                    end if;
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
    buff_next <= buff_reg;
    case state_reg is
        when idle =>
            phase_next <= (others => '0');
            done_next <= '0';
            if(start_dds = '1') then --
                   buff_next <= to_ufixed(data_in, input_t'high,input_t'low);
                   state_next <= normalization;           
             end if;
        when normalization =>
            buff_next <= resize(buff_reg * norm,input_t'high,input_t'low);
            state_next <= step_calc;
        when step_calc =>
            step_next <= resize(buff_reg * multiplier, data_t'high, data_t'low);
            state_next <= add_offset;
        when add_offset =>
            step_next <= resize(step_reg + offset, data_t'high, data_t'low);
            state_next <= strobe;
        when strobe =>
            phase_next <= resize(phase_reg + step_reg, data_t'high, data_t'low,fixed_wrap,fixed_truncate);
            if(phase_reg(31) = '1' and phase_next(31) = '0') then 
                done_next <= '1';
                state_next <= idle;     
            end if;
    end case;
end process;

start_sig <= done_reg;

end Behavioral;