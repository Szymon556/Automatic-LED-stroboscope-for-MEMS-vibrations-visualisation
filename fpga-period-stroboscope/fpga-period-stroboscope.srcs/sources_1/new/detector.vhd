library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;



entity detector is
    generic(
         -- Rozmiar danych wyjściowych
        INTEGER_PART_PERIOD : integer := 22;
        FRACTION_PART_PERIOD : integer := 0
    );
	port(
		clk   : in std_logic;
		reset : in std_logic;
		level : in std_logic;
		-- Komunikacja z Slave
		i_busy : in std_logic;
		o_stb : out std_logic;
		-- Dane wyjściowe
		period : out ufixed(INTEGER_PART_PERIOD - 1 downto FRACTION_PART_PERIOD)
	);
end detector;

architecture Behavioral of detector is
    
    constant one: ufixed(INTEGER_PART_PERIOD - 1 downto  FRACTION_PART_PERIOD ) := to_ufixed(1, INTEGER_PART_PERIOD - 1, FRACTION_PART_PERIOD );
    
	type state_type  is (WAIT_RISING,MEASURE_HIGH,CAPTURE_PERIOD);
	signal state_reg, state_next : state_type;
	signal level_reg, level_next : std_logic;
	signal counter_reg, counter_next : ufixed(INTEGER_PART_PERIOD - 1 downto FRACTION_PART_PERIOD);
	signal output_buff_reg, output_buff_next : ufixed(INTEGER_PART_PERIOD - 1 downto FRACTION_PART_PERIOD);
	signal tick_reg, tick_next : std_logic;
begin

	-- state register
	process(clk,reset) 
	begin
		if(reset = '1') then
			state_reg <= WAIT_RISING;
		else
			if(clk'event and clk = '1') then
				state_reg <= state_next;
			end if;
		end if;
	end process;
	
	-- level register
	process(clk, reset)
	begin
		if(reset = '1')  then
			level_reg <= '0';
			counter_reg <= (others => '0');
			output_buff_reg <= (others => '0');
			tick_reg <= '0';
		else
			if(clk'event and clk = '1') then
				level_reg <= level_next;
				counter_reg <= counter_next;
				output_buff_reg <= output_buff_next;
				tick_reg <= tick_next;
			end if;
		end if;
	end process;
	
	-- Komunikacja z Slave
	process(clk, reset)
	begin
           if(reset = '1')  then
                o_stb <= '0';
            else
                if(clk'event and clk = '1') then
                    o_stb <= '0';
                    if(not i_busy and o_stb) then
                        o_stb <= '0'; -- czyli zamien o_stb na low jeśli mam pewność że slave odebrał dane bo i_busy low
                    elsif(not o_stb) then
                        if(tick_reg = '1') then
                              o_stb <= '1';
                        end if;
                end if;
            end if;
        end if;
	end process;
	
	level_next <= level;
	
	-- next-state logic
	process(level,state_reg)
	begin
	    state_next <= state_reg;
		case state_reg is
			when WAIT_RISING => 
				if(level = '1' and level_reg = '0') then
					state_next <= MEASURE_HIGH;
				else
					state_next <= WAIT_RISING;
				end if;
			when MEASURE_HIGH =>
				if(level = '0' and level_reg = '1') then
					state_next <= CAPTURE_PERIOD;
				else
					state_next <= MEASURE_HIGH;
				end if;
			when CAPTURE_PERIOD => 
				if(level = '1' and level_reg = '0') then
					state_next <= MEASURE_HIGH;
				else
					state_next <= WAIT_RISING;
				end if;
			end case;
	end process;
	
	
	-- Moore output 
	process(all)
	begin
	   counter_next <= counter_reg;
	   output_buff_next <= output_buff_reg;
	   tick_next <= tick_reg;
		case state_reg is
			when WAIT_RISING|MEASURE_HIGH =>
				tick_next <= '0';
				counter_next <= resize(counter_reg + one ,INTEGER_PART_PERIOD - 1, FRACTION_PART_PERIOD);
			when CAPTURE_PERIOD =>
				tick_next <= '1';
				output_buff_next <= resize(counter_reg, INTEGER_PART_PERIOD - 1, FRACTION_PART_PERIOD);
				counter_next <= (others => '0');
		end case;
	end process;
	
	period <= resize(output_buff_reg,INTEGER_PART_PERIOD - 1, FRACTION_PART_PERIOD);
	
end Behavioral;
