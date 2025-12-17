
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.FIXED_FLOAT_TYPES.ALL;
use IEEE.FIXED_PKG.ALL;


entity filtr_3 is
 Generic(
   --==============================--
   -- Stosuję dwie różne wielkości --
   -- ponieważ DSP potrafi mnożyć  --
   -- liczby 18 x 25               --   
   --==============================--
   -- Wielkość Współczynników 
    INTEGER_BITS_COEFFICIENT : integer := 2;
    FRACTION_BITS_COEFFICIENT : integer := -23;
    -- Wielkość danych wejściowych
    INTEGER_BITS : integer := 2; 
    FRACTION_BITS : integer := -16 
  );
  Port ( 
        clk,reset : in std_logic;
        strobe : in std_logic;
        Xn : in sfixed(INTEGER_BITS - 1 downto FRACTION_BITS);
        Yn : out sfixed(INTEGER_BITS - 1 downto FRACTION_BITS);
        start : in std_logic;
        done_tick : out std_logic
  );
end filtr_3;

architecture Behavioral of filtr_3 is
subtype data_path is sfixed(INTEGER_BITS - 1 downto FRACTION_BITS);
    subtype coeff is sfixed(INTEGER_BITS_COEFFICIENT - 1 downto  FRACTION_BITS_COEFFICIENT);
    type state_type is (idle,set_registers,calc_producta1,calc_producta2, sum_producta1, sum_producta2,add_input,
    calc_productb0, sum_productb0, calc_productb1, sum_productb1, calc_productb2, sum_productb2,set_output,done);
    signal state_reg, state_next : state_type;
    
    -- Stałe do przechowywania wartośći współczynników
   constant b0 : coeff := to_sfixed(0.02008,INTEGER_BITS_COEFFICIENT - 1, FRACTION_BITS_COEFFICIENT); 
   constant b1 : coeff := to_sfixed(0.04017,INTEGER_BITS_COEFFICIENT - 1, FRACTION_BITS_COEFFICIENT);
   constant b2 : coeff := to_sfixed(0.02008,INTEGER_BITS_COEFFICIENT - 1, FRACTION_BITS_COEFFICIENT);
   
   constant a1 : coeff := to_sfixed(1.561 ,INTEGER_BITS_COEFFICIENT - 1, FRACTION_BITS_COEFFICIENT);
   constant a2 : coeff := to_sfixed(-0.6414 ,INTEGER_BITS_COEFFICIENT - 1, FRACTION_BITS_COEFFICIENT);
     
   
    
    
    -- Rejestry do przechowywania wyników mnożenia
    signal producta1_reg, producta1_next : data_path;
    signal producta2_reg, producta2_next : data_path;
    
    signal productb0_reg, productb0_next : data_path;
    signal productb1_reg, productb1_next : data_path;
    signal productb2_reg, productb2_next : data_path;
    
   
    --rejestry opóźniające
    signal reg_1, reg_1_next : data_path;
    signal reg_2, reg_2_next: data_path;
    
    -- rejestr do przechowywania próbki
    signal input_reg, input_reg_next : data_path;
    
    -- rejestr wartości wyjściowej
    signal output_reg,output_reg_next : data_path;
    
    -- rejestr do buforowania obliczonej wartości
    signal buff_yn : data_path;
    signal buff_yn_next : data_path;
    
    -- buforowanie danych wejściowych
    signal Xn_reg, Xn_next : data_path;
    
    signal helper_buff, helper_buff_next : data_path;
begin
    
    
    process(strobe,reset,clk)
    begin
        if(reset = '1') then
            input_reg <= (others => '0');
            reg_1 <= (others => '0');
            reg_2 <= (others => '0');
            producta1_reg <= (others => '0');
            producta2_reg <= (others => '0');
            productb0_reg <= (others => '0');
            productb1_reg <= (others => '0');
            productb2_reg <= (others => '0');
            Xn_reg <= (others => '0');
            helper_buff <= (others => '0');
         else
             if(clk'event and clk = '1') then
                    producta1_reg <=  producta1_next;
                    producta2_reg <=  producta2_next;
                    productb0_reg <=  productb0_next;
                    productb1_reg <=  productb1_next;
                    productb2_reg <=  productb2_next;
                    input_reg <= input_reg_next;
                    reg_1 <= reg_1_next; 
                    reg_2 <= reg_2_next;
                    Xn_reg <= Xn_next; 
                    helper_buff <= helper_buff_next;
             end if;    
         end if;
    end process;
    
    -- Aktualizacja maszyny stanów
    process(clk,reset)
    begin    
        if(reset = '1') then
            output_reg <= (others => '0');
            state_reg <= idle;
            buff_yn <= (others => '0');
        else
            if(clk'event and clk = '1') then
                    state_reg <= state_next;
                    output_reg <= output_reg_next;
                    buff_yn <= buff_yn_next;
            end if;
        end if;
    end process;
    
    -- FSMD
    process(all)
    begin
        state_next <= state_reg;
        input_reg_next <= input_reg;
        output_reg_next <= output_reg;
        buff_yn_next <= buff_yn;
        done_tick <= '0';
        producta1_next <=  producta1_reg;
        producta2_next <=  producta2_reg;
        productb0_next <=  productb0_reg;
        productb1_next <=  productb1_reg;
        productb2_next <=  productb2_reg;
        Xn_next <= Xn_reg;
        reg_1_next <= reg_1;
        reg_2_next <= reg_2;
        helper_buff_next <= helper_buff;
        case state_reg is
            when idle =>
                state_next <= idle;
                if (strobe = '1' and start = '1') then
                    Xn_next <= Xn;
                    reg_1_next <= helper_buff;
                    reg_2_next <= reg_1;
                    state_next <= set_registers;
                end if;   
            when set_registers =>
                input_reg_next <= (others=>'0');
                output_reg_next <= (others=>'0');
                producta1_next <= (others=>'0');
                producta2_next <= (others=>'0');
                productb0_next <= (others=>'0');
                productb1_next <= (others=>'0');
                productb2_next <= (others=>'0');
                state_next <= calc_producta1;
            when calc_producta1 =>
                producta1_next <= resize(reg_1 * a1, producta1_reg,fixed_saturate,fixed_truncate);
                state_next <= sum_producta1;
            when sum_producta1 =>
                input_reg_next <= resize(input_reg + producta1_reg,input_reg);
                state_next <= calc_producta2;
            when calc_producta2 =>
                producta2_next <= resize(reg_2 * a2, producta2_reg,fixed_saturate,fixed_truncate);
                state_next <= sum_producta2;
            when sum_producta2 =>
                input_reg_next <= resize(input_reg + producta2_reg,input_reg);
                state_next <= add_input;
            when add_input =>
                input_reg_next <= resize(input_reg + Xn_reg,input_reg);
                state_next <= calc_productb0;
            when calc_productb0 =>
                productb0_next <= resize(input_reg * b0,productb0_reg,fixed_saturate,fixed_truncate);
                state_next <= sum_productb0;
            when sum_productb0 =>
                output_reg_next <= resize(output_reg + productb0_reg, output_reg);
                state_next <= calc_productb1;
            when calc_productb1 =>
                productb1_next <= resize(reg_1 * b1,productb1_reg,fixed_saturate,fixed_truncate);
                state_next <= sum_productb1;
            when sum_productb1 =>
                output_reg_next <= resize(output_reg + productb1_reg, output_reg);
                state_next <= calc_productb2;
            when calc_productb2 =>
                productb2_next <= resize(reg_2 * b2,productb2_reg,fixed_saturate,fixed_truncate);
                state_next <= sum_productb2;
            when sum_productb2 =>
                output_reg_next <= resize(output_reg + productb2_reg, output_reg);
                state_next <= set_output;
            when set_output =>
                buff_yn_next <= resize(output_reg,buff_yn);
                state_next <= done;
            when done =>
                done_tick <= '1';
                state_next <= idle;
                helper_buff_next <= input_reg;
        end case;
    end process;
   Yn <= buff_yn;


end Behavioral;