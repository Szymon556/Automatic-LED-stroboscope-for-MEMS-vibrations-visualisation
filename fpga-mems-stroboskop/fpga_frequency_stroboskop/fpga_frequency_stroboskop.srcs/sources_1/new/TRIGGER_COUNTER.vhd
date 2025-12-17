library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

--==============================--
--         Wyzwalanie CE        --
--                              --
--==============================--
entity trigger_counter is
 Port ( 
    clk : in std_logic;
    start : in std_logic;
    reset : in std_logic;
    output : out std_logic
  );
end trigger_counter;

architecture Behavioral of trigger_counter is
    constant W : integer := 34;
    type state_type is (idle, counting, done);
    signal state_reg, state_next : state_type;
    signal phase_reg, phase_next : unsigned(W-1 downto 0) := (others => '0');
    signal tick : std_logic;
    -- round(2^32 * 100 / 10^8) ~ 4295
    constant phase_step : unsigned(W-1 downto 0) := TO_UNSIGNED(42950, W); -- 1000 hz
begin
     process(clk,reset)
    begin
        if(reset = '1') then
            phase_reg <= (others => '0');
            state_reg <= idle;
        else
            if(clk'event and clk = '1') then
                phase_reg <= phase_next;
                state_reg <= state_next;
            end if;
        end if;
    end process;
    
    process(all)
    begin
        phase_next <= phase_reg;
        state_next <= state_reg;
        tick <= '0';
        case state_reg is
            when idle =>
                if(start = '1') then
                    state_next <= counting;
                    phase_next <= (others => '0');
                end if;
            when counting =>
                if(phase_reg(32) = '1') then
                    state_next <= done;
                 else
                    phase_next <= phase_reg + phase_step;
                end if;
            when done =>
                tick <= '1';
                state_next <= idle;
        end case;
    end process;
    
    output <= tick;

end Behavioral;