
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity kirsch is
  port(
    ------------------------------------------
    -- main inputs and outputs
    i_clock    : in  std_logic;                      
    i_reset    : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  std_logic_vector(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out std_logic_vector(2 downto 0);                      
    o_mode     : out std_logic_vector(1 downto 0);
    o_row      : out std_logic_vector(7 downto 0);
    o_value    : out unsigned(12 downto 0);
    o_value2   : out unsigned(12 downto 0);
    ------------------------------------------
    -- debugging inputs and outputs
    debug_key      : in  std_logic_vector( 3 downto 1) ; 
    debug_switch   : in  std_logic_vector(17 downto 0) ; 
    debug_led_red  : out std_logic_vector(17 downto 0) ; 
    debug_led_grn  : out std_logic_vector(5  downto 0) ; 
    debug_num_0    : out std_logic_vector(3 downto 0) ; 
    debug_num_1    : out std_logic_vector(3 downto 0) ; 
    debug_num_2    : out std_logic_vector(3 downto 0) ; 
    debug_num_3    : out std_logic_vector(3 downto 0) ; 
    debug_num_4    : out std_logic_vector(3 downto 0) ;
    debug_num_5    : out std_logic_vector(3 downto 0) 
    ------------------------------------------
  );  
end entity;


architecture main of kirsch is
  constant a_dir : std_logic_vector (2 downto 0) := "100";
  constant b_dir : std_logic_vector (2 downto 0) := "010";
  constant c_dir : std_logic_vector (2 downto 0) := "110";
  constant d_dir : std_logic_vector (2 downto 0) := "000";
  constant e_dir : std_logic_vector (2 downto 0) := "101";
  constant f_dir : std_logic_vector (2 downto 0) := "011";
  constant g_dir : std_logic_vector (2 downto 0) := "111";
  constant h_dir : std_logic_vector (2 downto 0) := "001";
  
  type memory_out is array (0 to 2) of std_logic_vector (7 downto 0);
  signal mem_write : std_logic_vector(2 downto 0);
  signal wnw_dir, nne_dir, ese_dir, ssw_dir, final_dir : std_logic_vector (2 downto 0);
  signal col_index, row_index, calc_state : std_logic_vector(7 downto 0);
  signal a,b,c,d,e,f,g,h,i,wnw_max,nne_max,ese_max,ssw_max : unsigned (7 downto 0);
  signal partial_sum : unsigned (12 downto 0);
  signal sum, clk1_total, clk2_total : unsigned (12 downto 0);
  signal final_sum, final_max, clk3_total, clk4_total : unsigned (12 downto 0);
  signal mem_out : memory_out;
  signal busy : std_logic;
  
  function "rol" (a : std_logic_vector; n : natural)
		return std_logic_vector
	is
	begin
		return std_logic_vector(unsigned(a) rol n);
	end function;
	
  function "sll" (a : std_logic_vector; n : natural)
		return std_logic_vector
	is
	begin
		return std_logic_vector(unsigned(a) sll n);
	end function;

  procedure DIR_MAX (signal first, second : in unsigned ;
                   constant first_dir, second_dir : in std_logic_vector;
                   signal result : out unsigned;
                   signal result_dir : out std_logic_vector) is
  begin
    if first >= second then
      result <= first;
      result_dir <= first_dir;
    else
      result <= second;
      result_dir <= second_dir;
    end if;
  end DIR_MAX;
  
begin  

  debug_num_5 <= X"E";
  debug_num_4 <= X"C";
  debug_num_3 <= X"E";
  debug_num_2 <= X"3";
  debug_num_1 <= X"2";
  debug_num_0 <= X"7";

  debug_led_red <= (others => '0');
  debug_led_grn <= (others => '0');

  MEM_GENERATION: for I in 0 to 2 generate
	mem: entity work.mem(main)
	port map (
		address 	=> col_index,
		clock   	=> i_clock,
		data  		=> i_pixel,
                wren    	=> mem_write(I),
                q  	 	=> mem_out(I)
                );
  end generate; 

  transfer_proc: process
    begin
      wait until rising_edge(i_clock);
      if i_valid = '1' then
        a <= b;
        b <= c;
        h <= i;
        i <= d;
        f <= e;
        g <= f;
        c <= unsigned(mem_out(to_integer(unsigned(mem_write(1 downto 0)))));
        d <= unsigned(mem_out(to_integer(unsigned("rol"(mem_write,1)(1 downto 0)))));
        e <= unsigned(i_pixel);
        
      else
      end if;
    end process;

  FSM : process
    begin
      wait until rising_edge(i_clock);
      if i_reset = '1' then
        o_mode <= "01";
      elsif busy = '1' then
        o_mode <= "11";
      else
        o_mode <= "10";
      end if;
    end process;

  position_proc: process
    begin
      wait until rising_edge(i_clock);
      calc_state <= "sll"(calc_state,1);
      if i_reset = '1' then
        row_index <= "00000000";
        col_index <= "00000000";
        calc_state <= "00000000";
        mem_write <= "001";
        busy <= '0';
      end if;
      if i_valid = '1' then
        calc_state(0) <= '1';
        busy <= '1';
        if col_index = "11111111" then
          mem_write <= "rol"(mem_write,1);
          col_index <= "00000000";
          if row_index = "11111111" then
            busy <= '0';
            row_index <= "00000000";
          else
            row_index <= std_logic_vector(unsigned(row_index) + 1);
          end if;
        else
          col_index <= std_logic_vector(unsigned(col_index) + 1);
        end if;
      end if;
    end process;

    pipeline_stage1_proc : process
    begin
      wait until rising_edge(i_clock);
      
      if calc_state(0) = '1' then
        -- w v. nw
        DIR_MAX(g, b, h_dir, a_dir, wnw_max, wnw_dir);
        partial_sum <= ("00000" & h) + ("00000" & a);
        clk1_total <= ("00000" & wnw_max) + partial_sum;--("00" & partial_sum);
        sum <= "0000000000" + partial_sum;--("00" & partial_sum);
      elsif calc_state(1) = '1' then
        -- n v. ne
        DIR_MAX(a, d, b_dir, c_dir, nne_max, nne_dir);
        partial_sum <= ("00000" & b) + ("00000" & c);
        clk1_total <= ("000" & nne_max) + partial_sum;--("00" & partial_sum);
        sum <= sum + partial_sum;--("00" & partial_sum);
      elsif calc_state(2) = '1' then
        -- e v. se
        DIR_MAX(c, f, d_dir, e_dir, ese_max, ese_dir);
        partial_sum <=  ("00000" & d) + ("00000" & e);
        clk1_total <= ("000" & ese_max) + partial_sum;--("00" & partial_sum);
        sum <= sum + partial_sum;--("00" & partial_sum);
      elsif calc_state(3) = '1' then
        -- s v. sw
        DIR_MAX(e, h, f_dir, g_dir, ssw_max, ssw_dir);
        partial_sum <= ("00000" & f) + ("00000" & g);
        clk1_total <= ("00000" & ssw_max) + partial_sum;--("00" & partial_sum);
        sum <= sum + partial_sum;--("00" & partial_sum);
      end if;
      
    end process;
   
    --final_sum_proc : process(partial_sum)
    --begin
    --  if calc_state(0) = '1' then
    --    sum <= "00000000000" +  ("00" & partial_sum);
    --  else
    --    sum <= sum + ("00" & partial_sum);
    --  end if;
    --end process;

    pipeline_stage2_proc : process
    begin
      wait until rising_edge(i_clock);
      o_valid <= '0';
      if calc_state(4) = '1' then
        DIR_MAX(clk4_total, clk3_total, wnw_dir, nne_dir, final_max, final_dir);
      elsif calc_state(5) = '1' then
        DIR_MAX(final_max, clk3_total, final_dir, ese_dir, final_max, final_dir);
      elsif calc_state(6) = '1' then
        DIR_MAX(final_max, clk3_total, final_dir, ssw_dir, final_max, final_dir);
      elsif calc_state(7) = '1' then
        if row_index >= "00000010" then
          if ("sll"(final_max, 3)) > final_sum then
            o_edge <= '1';
            o_dir <= final_dir;
          else
            o_edge <= '0';
            o_dir <= d_dir;
          end if;
           o_valid <= '1';
        end if;
      end if;
    end process;

    stage2_sum_proc : process
    begin
      wait until rising_edge(i_clock);
      if calc_state(4) = '1' then
        final_sum <= "sll"(sum,1) + sum;
      elsif calc_state(5) = '1' then
        final_sum <= final_sum + 383;
      else
        final_sum <= final_sum;
      end if;
    end process;

    clk_total_proc: process
      begin
        wait until rising_edge(i_clock);
        clk2_total <= clk1_total;
        clk3_total <= clk2_total;--"00" & clk2_total;
        clk4_total <= clk3_total;
      end process;
      
    o_row <= std_logic_vector(partial_sum(7 downto 0));
    o_value <= sum;
    o_value2 <= final_sum;

end architecture;


      
