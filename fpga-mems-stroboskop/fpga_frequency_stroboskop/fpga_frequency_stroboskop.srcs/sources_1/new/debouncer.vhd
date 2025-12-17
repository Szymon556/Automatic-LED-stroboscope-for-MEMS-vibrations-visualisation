library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity debouncer is
    generic(
        N: integer:= 19
    );
	port(
		sw : in std_logic;
		clk : in std_logic;
		reset : in std_logic;
		db : buffer std_logic 
		
	);
end debouncer;

architecture Behavioral of debouncer is
	signal q_reg, q_next: unsigned(N - 1 downto 0) :=  (others => '0');
	signal m_tick : std_logic;
	type  state_type is (zero, wait1_1, wait1_2, wait1_3,wait0_1, wait0_2, wait0_3,one);
	signal state_reg, state_next: state_type;
begin
	

	process(clk,reset)
		begin
		    if (reset = '1') then
		        q_reg <= (others => '0');
		    else
		        if (clk'event and clk ='1') then
				    q_reg <= q_next;
			    end if;
		    end if;
	end process;

	q_next <= q_reg + 1;
	
	
	m_tick <= '1' when q_reg=0 else 
				 '0';
	

	process (clk)
	begin
		if (reset = '1') then 
			state_reg <= zero;
		elsif (clk'event and clk ='1') then
			state_reg <= state_next;
		end if;
	end process;
	
	
	process(state_reg, sw, m_tick)
	begin
	state_next <= state_reg;
	db <= '0';
	case state_reg is
		when zero =>
			if sw = '1' then
				state_next <= wait1_1;
			end if;
		when wait1_1 =>
			if sw = '0' then
				state_next <= zero;
			else 
				if m_tick = '1' then
					state_next <= wait1_2;
				end if;
			end if;
		when wait1_2 =>
			if sw = '0' then
				state_next <= zero;
			else 
				if m_tick = '1' then
					state_next <= wait1_3;
				end if;
			end if;
		when wait1_3 =>
			if sw = '0' then
				state_next <= zero;
			else 
				if m_tick = '1' then
					state_next <= one;
				end if;
			end if;
		when one =>
			db <= '1';
			if sw ='0' then
				state_next <= wait0_1;
			end if;
	    when wait0_1 =>
			if sw = '1' then
				state_next <= one;
			else 
				if m_tick = '1' then
					state_next <= wait0_2;
				end if;
			end if;
		when wait0_2 =>
			if sw = '1' then
				state_next <= one;
			else 
				if m_tick = '1' then
					state_next <= wait0_3;
				end if;
			end if;
		when wait0_3 =>
			if sw = '1' then
				state_next <= one;
			else 
				if m_tick = '1' then
					state_next <= zero;
				end if;
			end if;
	end case;
	end process;
end Behavioral;