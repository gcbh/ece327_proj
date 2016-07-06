
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
  signal mem_write : std_logic_vector(0 to 2);
  signal col_index, row_index,a,b,c,d,e,f,g,h,i : std_logic_vector(0 to 7);
  signal mem_out : array (0 to 2) of std_logic_vector(0 to 7);
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

        c <= mem_out(resize("rol"(mem_write,1), 2));
        d <= mem_out(resize("rol"(mem_write,2), 2));
        e <= i_pixel;
        
      else
      end if;
    end process;

  position_proc: process
    begin
      wait until rising_edge(i_clock);
      if i_reset = '1' then
        row_index <= "00000000";
        col_index <= "00000000";
        mem_write <= "001";
      elsif i_valid = '1' then
        if col_index = "11111111" then
          row_index = row_state + 1;
          mem_write <= "rol"(mem_write,1);
          col_index <= "00000000";
        elsif row_index = "11111111" then
          -- conclude
        else
          col_index <= col_index + 1; 
        end if;
      end if;
    end process;
  
end architecture;

procedure DIR_MAX (signal first, first_dir, second, second_dir: in std_logic_vector;
                   signal result, result_dir : out std_logic_vector) is
begin
  if first >= second then
    result = first;
    result_dir = first_dir;
  else
    result= second;
    result_dir = second_dir;
  end if;
end DIR_MAX;
      
