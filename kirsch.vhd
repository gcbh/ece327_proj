
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
  signal nnw_dir, nee_dir, ses_dir, sww_dir, final_dir : std_logic_vector (3 downto 0);
  signal col_index, row_index, calc_state,a,b,c,d,e,f,g,h,i,nnw_max,nee_max,ses_max,sww_max : std_logic_vector(0 to 7);
  signal partial_sum : std_logic_vector (8 downto 0);
  signal sum, nnw_total, nee_total, ses_total, sww_total, final_max, final_sum : std_logic_vector (9 downto 0);
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

  procedure DIR_MAX (signal first, first_dir, second, second_dir: in std_logic_vector;
                   signal result, result_dir : out std_logic_vector) is
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
        c <= mem_out(to_integer(unsigned(mem_write(1 downto 0))));
        d <= mem_out(to_integer(unsigned("rol"(mem_write,1)(1 downto 0))));
        e <= i_pixel;
        
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
            row_index = "00000000";
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
        DIR_MAX(h=>first, h_dir=>first_dir,c=>second, c_dir=>second_dir, nnw_dir=>result_dir, nnw_max=>result);
      elsif calc_state(1) = '1' then
        DIR_MAX(b=>first, b_dir=>first_dir,e=>second, e_dir=>second_dir, nee_dir=>result_dir, nee_max=>result);
      elsif calc_state(2) = '1' then
        DIR_MAX(d=>first, d_dir=>first_dir,g=>second, g_dir=>second_dir, ses_dir=>result_dir, ses_max=>result);
      elsif calc_state(3) = '1' then
        DIR_MAX(a=>first, a_dir=>first_dir,f=>second, f_dir=>second_dir, sww_dir=>result_dir, sww_max=>result);
      end if;
      
    end process;
    
    partial_sum_proc : process
    begin
      wait until rising_edge(i_clock);
      if calc_state(0) = '1' then
        partial_sum <= a + b;
      elsif calc_state(1) = '1' then
        partial_sum <= c + d;
      elsif calc_state(2) = '1' then
        partial_sum <= e + f;
      elsif calc_state(3) = '1' then
        partial_sum <= g + h;
      end if;
    end process;
    
    dir_sum_proc : process(nnw_max, nee_max, ses_max, sww_max, partial_sum)
    begin
      if calc_state(0) = '1' then
        nnw_total <= nnw_max + partial_sum;
      elsif calc_state(1) = '1' then
        nee_total <= nee_max + partial_sum;
      elsif calc_state(2) = '1' then
        ses_total <= ses_max + partial_sum;
      elsif calc_state(3) = '1' then
        sww_total <= sww_max + partial_sum;
      end if;
    end process;

    final_sum_proc : process(partial_sum)
    begin
      if calc_state(0) = '1' then
        sum <= partial_sum;
      else
        sum <= sum + partial_sum;
      end if;
    end process;

    pipeline_stage2_proc : process
    begin
      wait until rising_edge(i_clock);
      o_valid <= '0';
      if calc_state(4) = '1' then
        DIR_MAX(nnw_total=>first, nnw_dir=>first_dir,nee_total=>second, nee_dir=>second_dir, final_dir=>result_dir, final_max=>result);
      elsif calc_state(5) = '1' then
        DIR_MAX(final_max=>first, final_dir=>first_dir,ses_total=>second, ses_dir=>second_dir, final_dir=>result_dir, final_max=>result);
      elsif calc_state(6) = '1' then
        DIR_MAX(final_max=>first, final_dir=>first_dir,sww_total=>second, sww_dir=>second_dir, final_dir=>result_dir, final_max=>result);
      elsif calc_state(7) = '1' then
        o_valid <= '1';
        if (final_max & "000") > final_sum then
          o_edge <= '1';
          o_dir <= final_dir;
        else
          o_edge <= '0';
          o_dir <= "000";
      end if;
    end process;

    stage2_sum_proc : process
    begin
      wait until rising_edge(i_clock);
      if calc_state(4) = '1' then
        final_sum <= (sum & "0") + sum;
      elsif calc_state(5) = '1' then
        final_sum <= final_sum + 383;
    end process;

end architecture;


      
