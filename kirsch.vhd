
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
  signal dir1, dir2, dir3, dir4, final_dir : std_logic_vector (2 downto 0);
  signal col_index, row_index, calc_state : std_logic_vector(7 downto 0);
  signal a,b,c,d,e,f,g,h,i,dir1_max : unsigned (7 downto 0);
  signal partial_sum : unsigned (8 downto 0);
  signal clk1_total, clk2_total, clk3_total, clk4_total, final_max : unsigned (9 downto 0);
  signal sum, final_sum : unsigned (12 downto 0);
  signal mem_out : memory_out;
  signal busy, sum_zero : std_logic;
  
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

  procedure DIR_MAX (constant first, second : in unsigned ;
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
    
  position_proc : process
  begin
    wait until rising_edge(i_clock);
    if i_reset = '1' then
      busy <= '0';
      col_index <= "00000000";
      row_index <= "00000000";
      mem_write <="001";
    elsif i_valid = '1' then
      busy <= '1';
      col_index <= std_logic_vector(unsigned(col_index) + 1);
      if col_index = "11111111" then
        if (row_index = "11111111") then
          busy <= '0';
        end if;
        row_index <= std_logic_vector(unsigned(row_index) + 1);
        mem_write <= "rol" (mem_write,1);
      end if;
    end if;
  end process;
  
  conv_table_proc : process
  begin
    wait until rising_edge(i_clock);
    if i_valid = '1' then
      a <= b;
      h <= i;
      g <= f;
      b <= c;
      i <= d;
      f <= e;
      c <= unsigned(mem_out(to_integer(unsigned(mem_write(1 downto 0)))));
      d <= unsigned(mem_out(to_integer(unsigned("rol"(mem_write,1)(1 downto 0)))));
      e <= unsigned(i_pixel);
    end if;	
  end process;

  calc_state_proc : process
  begin
    wait until rising_edge(i_clock);
    if i_reset = '1' then
       calc_state <= "00000000";
    else
      calc_state <= "sll"(calc_state, 1);
      if i_valid = '1' and (unsigned(col_index) > 1 and unsigned(row_index) > 1) then
        calc_state(0) <= '1';
      end if;
    end if;
  end process;

  pipeline_stage1_proc : process
  begin
    wait until rising_edge(i_clock);
    if i_reset = '0' then
      if calc_state(0) = '1' then
        -- w v. nw
        DIR_MAX(g, b, h_dir, a_dir, dir1_max, dir1);
      elsif calc_state(1) = '1' then
        -- n v. ne
        DIR_MAX(a, d, b_dir, c_dir, dir1_max, dir1);
      elsif calc_state(2) = '1' then
        -- e v. se
        DIR_MAX(c, f, d_dir, e_dir, dir1_max, dir1);
      elsif calc_state(3) = '1' then
        -- s v. sw
        DIR_MAX(e, h, f_dir, g_dir, dir1_max, dir1);
      end if;
    end if;
  end process;

  partial_sum_proc: process
  begin
    wait until rising_edge(i_clock);
    if i_reset = '0' then
      if calc_state(0) = '1' then
        partial_sum <= ("0" & h) + ("0" & a);
        sum_zero <= '1';
      elsif calc_state(1) = '1' then
        partial_sum <= ("0" & b) + ("0" & c);
        sum_zero <= '0';
      elsif calc_state(2) = '1' then
        partial_sum <=  ("0" & d) + ("0" & e);
        sum_zero <= '0';
      elsif calc_state(3) = '1' then
        partial_sum <= ("0" & f) + ("0" & g);
        sum_zero <= '0';
      end if;
    end if;
  end process;

  sum_stage1_proc : process (partial_sum, sum_zero)
  begin
    if sum_zero = '1'  then
      sum <= "00000000000" + ("0000" & partial_sum);
    else
      sum <= sum + ("0000" & partial_sum);
    end if;
  end process;
  
  clk1_proc : process(partial_sum, dir1_max)
  begin
    clk1_total <= ("00" & dir1_max) + ("0" & partial_sum);
  end process;

  pipeline_stage2_proc : process
  begin
    wait until rising_edge(i_clock);
    o_valid <= '0';
    if calc_state(4) = '1' then
      DIR_MAX(clk4_total, clk3_total, dir4, dir3, final_max, final_dir);
    elsif calc_state(5) = '1' then
      DIR_MAX(final_max, clk3_total, final_dir, dir3, final_max, final_dir);
    elsif calc_state(6) = '1' then
      DIR_MAX(final_max, clk3_total, final_dir, dir3, final_max, final_dir);
    elsif calc_state(7) = '1' then
      if row_index >= "00000010" then
        if (final_max & "000") > final_sum then
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
      final_sum <= "sll"(sum, 1) + sum;
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
    clk3_total <= clk2_total;
    clk4_total <= clk3_total;
  end process;

  dir_process : process
  begin
    wait until rising_edge(i_clock);
    dir2 <= dir1;
    dir3 <= dir2;
    dir4 <= dir3;
  end process;
    
  o_row <= calc_state;

end architecture;


      
