
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
  signal dir_1, dir_2, nnw_dir, nee_dir, ses_dir, sww_dir, final_dir : std_logic_vector (2 downto 0);
  signal col_index, row_index, calc_state : std_logic_vector(7 downto 0);
  signal a,b,c,d,e,f,g,h,i,nnw_max,nee_max,ses_max,sww_max : unsigned (7 downto 0);
  signal partial_sum : unsigned (8 downto 0);
  signal sum, clk1_total, clk2_total : unsigned (10 downto 0);
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
                     signal first_dir, second_dir : in std_logic_vector;
                   signal result : out unsigned;
                   signal result_dir : out std_logic_vector) is
  begin
    if first >= second then
      result <= unsigned(first);
      result_dir <= first_dir;
    else
      result <= unsigned(second);
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
      elsif i_valid = '1' then
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
      if i_valid = '1' then
        dir_1 <= h_dir;
        dir_2 <= c_dir;
      elsif calc_state(0) = '1' then
        DIR_MAX(h, c, dir_1, dir_2, nnw_max, nnw_dir);
        partial_sum <= ("0" & a) + ("0" & b);
        dir_1 <= b_dir;
        dir_2 <= e_dir;
        clk1_total <= ("000" & nnw_max) + ("00" & partial_sum);
      elsif calc_state(1) = '1' then
        DIR_MAX(b, e, dir_1, dir_2, nee_max, nee_dir);
        partial_sum <= ("0" & c) + ("0" & d);
        dir_1 <= d_dir;
        dir_2 <= g_dir;
        clk1_total <= ("000" & nee_max) + ("00" & partial_sum);
      elsif calc_state(2) = '1' then
        DIR_MAX(d, g , dir_1, dir_2, ses_max, ses_dir);
        partial_sum <=  ("0" & e) + ("0" & f);
        dir_1 <= a_dir;
        dir_2 <= f_dir;
        clk1_total <= ("000" & ses_max) + ("00" & partial_sum);
      elsif calc_state(3) = '1' then
        DIR_MAX(a, f, dir_1, dir_2, sww_max, sww_dir);
        partial_sum <= ("0" & g) + ("0" & h);
        clk1_total <= ("000" & sww_max) + ("00" & partial_sum);
      end if;
      
    end process;
   
    final_sum_proc : process(partial_sum, i_valid)
    begin
      if i_valid = '1' then
        sum <= "00000000000";
      else
        sum <= sum + ("00" & partial_sum);
      end if;
    end process;

    pipeline_stage2_proc : process
    begin
      wait until rising_edge(i_clock);
      o_valid <= '0';
      if calc_state(4) = '1' then
        DIR_MAX(clk4_total, clk3_total, nnw_dir, nee_dir, final_max, final_dir);
      elsif calc_state(5) = '1' then
        DIR_MAX(final_max, clk3_total, final_dir, ses_dir, final_max, final_dir);
      elsif calc_state(6) = '1' then
        DIR_MAX(final_max, clk3_total, final_dir, sww_dir, final_max, final_dir);
      elsif calc_state(7) = '1' then
        if row_index >= "00000010" and col_index >= "00000010" then
        o_valid <= '1';
        if ("sll"(final_max, 3)) > final_sum then
          o_edge <= '1';
          o_dir <= final_dir;
        else
          o_edge <= '0';
          o_dir <= "000";
        end if;
        end if;
      end if;
    end process;

    stage2_sum_proc : process
    begin
      wait until rising_edge(i_clock);
      if calc_state(4) = '1' then
        final_sum <= ("sll"(("00" & sum), 1)) + ("00" & sum);
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
        clk3_total <= "00" & clk2_total;
        clk4_total <= clk3_total;
      end process;

    
    o_row <= calc_state;
    o_value <= final_sum;
    o_value2 <= "sll"(final_max,3);

end architecture;


      
