
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package project_pkg is
	subtype vec is std_logic_vector(7 downto 0);
	type vec_vec is array (2 downto 0) of vec;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.project_pkg.all;

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

	signal a, b, c, h, i, d, g, f, e : unsigned(9 downto 0);
	signal busy_flag, done_flag : std_logic;
	signal col_index,  v_row   : std_logic_vector(7 downto 0);
	signal mem_write   : std_logic_vector(2 downto 0);
	signal mem_out     : vec_vec;
	signal vrow1data : unsigned(7 downto 0);
	signal vrow2data : unsigned(7 downto 0);
	signal vbits															: std_logic_vector(7 downto 0);
	signal p1_dir1, p1_dir2, p1_dir3, p1_dir4, p2_dir1, p2_dir2, p2_dir3	: std_logic_vector(2 downto 0);
	signal p1_max1, p1_max2, p1_max3, p1_max4, p2_max1, p2_max2, p2_max3	: unsigned(9 downto 0);
	signal p1_sum1, p1_sum2, p1_sum3, p1_sum4, p2_sum						: unsigned(11 downto 0);

	
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

	MEM_GENS: for I in 0 to 2 generate
	mem: entity work.mem(main)
	port map (
		address 	=> col_index,
		clock   	=> i_clock,
		data  		=> i_pixel,
		wren    	=> mem_write(I),
		q  	 		=> mem_out(I)
	);
	end generate;
			
	-- 8 bit counter to represent bottom right location of convolution table
	process begin
		wait until rising_edge(i_clock);
			if i_reset = '1' then
				col_index <= "00000000";
				mem_write <="001";
				v_row <= "00000000";
				done_flag <= '0';
				busy_flag <= '0';
			elsif i_valid = '1' then
				if done_flag = '1' then
					done_flag <= '0';
					v_row <= "00000000";
				end if;
				busy_flag <= '1';
				col_index <= std_logic_vector(unsigned(col_index) + 1);
				if col_index = "11111111" then
					mem_write <= "rol" (mem_write,1);
					if (v_row = "11111111") then
						busy_flag <= '0';
						done_flag <= '1';
					else
						v_row <= std_logic_vector(unsigned(v_row) + 1);
					end if;
				end if;
			end if;
	end process;
	
	-- mux to determine mapping between actual row count and virtual row count
	process (mem_write,mem_out,i_pixel) begin
		case mem_write is
			when "001" =>
				vrow1data <= unsigned(mem_out(1));
				vrow2data <= unsigned(mem_out(2));
			when "010" =>
				vrow1data <= unsigned(mem_out(2));
				vrow2data <= unsigned(mem_out(0));
			when "100" =>
				vrow1data <= unsigned(mem_out(0));
				vrow2data <= unsigned(mem_out(1));
			when others =>
				vrow1data <= "00000000";
				vrow2data <= "00000000";
		end case;	
	end process;
	

	process begin
		wait until rising_edge(i_clock);
			-- shift values left in convolution table
		if i_valid = '1' then
			a <= b;
			h <= i;
			g <= f;
			b <= c;
			i <= d;
			f <= e;
			-- load new data in
			c <= "00" & vrow1data;
			d <= "00" & vrow2data;
			e <= "00" & unsigned(i_pixel);
		end if;
	

	end process;
	
	-- mode control
	process begin
		wait until rising_edge(i_clock);
		if i_reset =  '1' then
			o_mode <= "01";
		elsif busy_flag = '1' then
			o_mode <= "11";
		else
			o_mode <= "10";
		end if;
	end process;

	-- Pipes
	process begin
		wait until rising_edge(i_clock);
		o_valid <= '0';
		if i_reset = '1' then
			vbits <= "00000000";
		else
			vbits <= "sll"(vbits, 1);
			if i_valid = '1' and ((col_index = "11111111" and unsigned(v_row) > 2) or (unsigned(v_row) > 1  and  unsigned(col_index) > 1)) then
				vbits(0) <= '1';
			end if;
			if vbits(0) = '1' then
				if  (g < b) then
					p1_max1 <= b + a + h;
					--NW
					p1_dir1 <= "100";
				else
					--  (Covers priority)
					p1_max1 <= g + a + h;	
					--W
					p1_dir1 <= "001";
				end if;
				p1_sum1 <= ("00" & a) + ("00" & h);
			end if;		
			if vbits(1) = '1' then
				if  (a < d) then
					p1_max2 <= d + b + c;	
					--NE
					p1_dir2 <= "110";
				else
					p1_max2 <= a + b + c;
					--N
					p1_dir2 <= "010";
				end if;
				p1_sum2 <= ("00" & b) + ("00" & c);
			end if;		
			if vbits(2) = '1' then
				if  (c < f) then
					p1_max3 <= f + d + e;	
					--SE
					p1_dir3 <= "101";
				else
					p1_max3 <= c + d + e;
					--E
					p1_dir3 <= "000";
				end if;
				p1_sum3 <= ("00" & e) + ("00" & d);
			end if;		
			if vbits(3) = '1' then
				if  (e < h) then
					p1_max4 <= h + g + f;	
					--SW
					p1_dir4 <= "111";
				else
					p1_max4 <= e + g + f;
					--S
					p1_dir4 <= "011";
				end if;
				p1_sum4 <= ("00" & g) + ("00" & f);
			end if;		
			if vbits(4) = '1' then
				if  (p1_max1 < p1_max2) then
					p2_max1 <= p1_max2;	
					p2_dir1 <= p1_dir2;
				else
					p2_max1 <= p1_max1;
					p2_dir1 <= p1_dir1;
				end if;
				p2_sum <= p1_sum1 + p1_sum2;
			end if;
			if vbits(5) = '1' then
				if  (p1_max3 < p1_max4) then
					p2_max2 <= p1_max4;	
					p2_dir2 <= p1_dir4;
				else
					p2_max2 <= p1_max3;
					p2_dir2 <= p1_dir3;
				end if;
				p2_sum <= p2_sum + p1_sum3;
			end if;
			if vbits(6) = '1' then
				if  (p2_max1 < p2_max2) then
					p2_max3 <= p2_max2;
					p2_dir3 <= p2_dir2;
				else
					p2_max3 <= p2_max1;
					p2_dir3 <= p2_dir1;
				end if;
				p2_sum <= p2_sum + p1_sum4;
			end if;
			if vbits(7) = '1' then
				if ((p2_max3 & "000") - ((p2_sum & '0') + p2_sum)) > 383 then
					o_edge <= '1';
					o_dir <= p2_dir3;
				else
					o_edge <= '0';
					o_dir <= "000";
				end if;
				o_valid <=  '1';
				-- setup debug convolution table
			end if;
		end if;
	end process;

	o_row <= v_row;

end architecture;
