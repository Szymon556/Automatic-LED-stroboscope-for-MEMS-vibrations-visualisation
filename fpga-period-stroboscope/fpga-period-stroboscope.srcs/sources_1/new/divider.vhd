library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.fixed_float_types.all;
use IEEE.fixed_pkg.all;

use IEEE.NUMERIC_STD.ALL;

--=========================================
-- W tej implementacji będę zwracał tylko --
-- część całkowitą bez reszty z dzielenia --
--========================================--

entity divider is
    generic(
        -- Rozmiar danych wejściowych
        INTEGER_PART_INPUT : integer := 22;
        FRACTION_PART_INPUT : integer := 0;
         -- Rozmiar danych znormalizowanych dzisiętnie
        INTEGER_PART_NORM : integer := 1;
        FRACTION_PART_NORM : integer := -22;
             -- Rozmiar danych przesuniętych w lewo podczas normalizacji
        INTEGER_PART_DATA : integer := 22;
        FRACTION_PART_DATA : integer := 0;
        -- Stałe potrzebne do wykonania dzielenia
        W : integer := 22;
        CBIT : integer := 5
        
    );
	port(
	    clk : in std_logic;
	    reset : in std_logic;
        -- Sygnały odpowiedzialne za kontrole odbioru danych
        i_stb : in std_logic;
        o_busy : out std_logic;
        
        -- Sygnały odpowiedzialne za wysyałanie danych
        o_stb : out std_logic;
        i_busy : in std_logic;
        
       
        divisor : in ufixed(INTEGER_PART_INPUT - 1 downto FRACTION_PART_INPUT);
        output_data : out ufixed(INTEGER_PART_DATA - 1 downto FRACTION_PART_DATA)
        
        --test : out std_logic
	);
end divider;

architecture Behavioral of divider is

    -- Dane odbierane i buforowane
    subtype input_t is ufixed(INTEGER_PART_INPUT - 1  downto FRACTION_PART_INPUT);
     -- Dane znormalizowane dziesiętnie
    subtype norm_t is ufixed(INTEGER_PART_NORM downto FRACTION_PART_NORM); -- jak dam INTEGER_PART_NORM  - 1, to nie działa resize, czyli nie do końca poprawnia działają sfixed bez części całkowitej
    -- Dane przesuwane w lewo
    subtype data_t is ufixed(INTEGER_PART_DATA - 1  downto FRACTION_PART_DATA);
    
    -- stałe (bo zawsze dzielimy przez 1)
    constant dvnd : unsigned(W-1 downto 0) := to_unsigned(1048576, W); -- dla 100 hz 65536
    constant C1_E8 : ufixed(0 downto -40) := to_ufixed(1.0E-8, 0,-40);
    constant shift_const : data_t := to_ufixed(1048576,data_t'high, data_t'low);
    
	type state_type is (idle,left_shift,op,last,done);
	signal state_reg,state_next :state_type;
	signal rh_reg, rh_next : unsigned(W - 1 downto 0);
	signal rl_reg, rl_next : std_logic_vector(W - 1 downto 0);
	signal rh_tmp : unsigned(W - 1 downto 0);
	signal d_reg, d_next : unsigned(W - 1 downto 0);
	signal n_reg, n_next : unsigned(CBIT - 1 downto 0);
	signal q_bit :  std_logic;
	signal norm_reg, norm_next : norm_t;
	
	-- sygnał do buforowania danych
	signal buff_data : input_t;
	signal buff_output_reg,buff_output_next : std_logic_vector(W - 1 downto 0);
	-- Buforowanie o_busy
    signal r_busy : std_logic;
    signal done_reg, done_next :std_logic;
	signal start_reg,start_next : std_logic;	
begin
	
	  -- Proces odpowidzialny za komunikacje z Master/Slave oraz maszynę stanów
    process(clk,reset)
    begin
        if(reset = '1') then
            state_reg <= idle;
            buff_data <= (others => '0');
            rh_reg <= (others => '0');
            rl_reg <= (others => '0');
            d_reg <= (others => '0');
            n_reg <= (others => '0');
            buff_output_reg <= (others => '0');
            norm_reg <= (others => '0');
            start_reg <= '0';
            r_busy <= '0';
            o_stb <= '0';
            done_reg <= '0';  
         else
            if(rising_edge(clk)) then
                state_reg <= state_next;
                done_reg <= done_next;
                start_reg <= start_next;
                norm_reg <= norm_next;
                rh_reg <= rh_next;
                rl_reg <= rl_next;
                d_reg <= d_next;
                n_reg <= n_next; 
                buff_output_reg <= buff_output_next;
                if( not o_busy) then
                    o_stb <= '0';
                    -- Odbieramy dane
                    if(i_stb) then
                        r_busy <= '1';
                        start_reg <= '1';
                        buff_data <= divisor;
                        
                    end if;
                 -- Nie możemy wysłać danych 
                 elsif((o_stb) and (not i_busy)) then
                    r_busy <= '0';
                    o_stb <= '0';
                elsif(not o_stb) then
                    if(done_reg = '1') then
                        o_stb <= '1';
                        start_reg <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- FSMD
    process(all)
    begin
        state_next <= state_reg;
        norm_next <= norm_reg;
        rh_next <= rh_reg;
        rl_next <= rl_reg;
        d_next <= d_reg;
        n_next <= n_reg;
        start_next <= start_reg;
        done_next <= done_reg;
        buff_output_next <= buff_output_reg;
        case state_reg is
            when idle=>
                done_next <= '0';
                if(start_reg = '1') then
                    rh_next <= (others => '0');
                    rl_next <= std_logic_vector(dvnd);
                    norm_next <= resize(C1_E8  * buff_data, norm_t'high, norm_t'low);
                    n_next <= to_unsigned(W + 1, CBIT);
                    state_next <= left_shift;
                end if;
             when left_shift =>
                d_next <= unsigned(to_slv(resize(norm_reg * shift_const, data_t'high,data_t'low))); 
                state_next <= op;
            when op=>
                rl_next <= rl_reg(W - 2 downto 0) & q_bit;
                rh_next <= rh_tmp(W - 2 downto 0) & rl_reg(W - 1);
                n_next <= n_reg - 1;
               -- test <= '1';
                if(n_next = 1) then
                    state_next <= last;
                end if;
            when last =>
                rl_next <= rl_reg(W - 2 downto 0) & q_bit;
                rh_next <= rh_tmp;
                state_next <= done;
            when done =>
                state_next <= idle;
                buff_output_next <= rl_reg;
                done_next <= '1';
        end case;     
    end process;
   
   process(rh_reg, d_reg)
   begin
    if rh_reg >= d_reg then
        rh_tmp <= rh_reg - d_reg;
        q_bit <= '1';
     else
        rh_tmp <= rh_reg;
        q_bit <= '0';
    end if;
   end process; 
    
o_busy <= r_busy;
output_data <= to_ufixed(buff_output_reg,data_t'high, data_t'low);
	
end Behavioral;
