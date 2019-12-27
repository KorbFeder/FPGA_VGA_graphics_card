-- CREATOR: Michael Braun

library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 

entity MEM_CTRL is
	port(-- OUTPUT
	     R_R, R_G, R_B : out std_logic_vector(3 downto 0) := "0000";
	     R_ADDR: in std_logic_vector (18 downto 0);
	     R_CLK: in std_logic;
	     -- INPUT
	     W_R, W_G, W_B : in std_logic_vector(3 downto 0) := "0000";
	     W_ADDR: in std_logic_vector (18 downto 0);
	     W_CLK: in std_logic;
	     RESET: in std_logic);
end MEM_CTRL;

architecture BEHAV of MEM_CTRL is
	-- type declarations
	--type ram_line_type	is array (0 to 639) of std_logic_vector(11 downto 0);
	--type ram_type		is array (0 to 479) of ram_line_type;
	-- signals
	--signal RAM: ram_type := (others => (others => (others => '0')));
	--signal RAM: ram_type := (others => (others => "000011110000")); 
begin
	READ: process(R_CLK, RESET)
	begin
		if(RESET = '1') then
			R_R <= "0000";
			R_G <= "0000";
			R_B <= "0000";
		elsif(R_CLK = '1' and R_CLK'event) then
		    R_R <= "1111";
			R_G <= "0000";
			R_B <= "0000";
		--	R_R <= RAM(to_integer(unsigned(R_ADDR(18 downto 10))))(to_integer(unsigned(R_ADDR(9 downto 0))))(3 downto 0);
		--	R_G <= RAM(to_integer(unsigned(R_ADDR(18 downto 10))))(to_integer(unsigned(R_ADDR(9 downto 0))))(7 downto 4);
		--	R_B <= RAM(to_integer(unsigned(R_ADDR(18 downto 10))))(to_integer(unsigned(R_ADDR(9 downto 0))))(11 downto 8);
		end if;
	end process READ;
	
	WRITE: process(W_CLK, RESET)
	begin
		if(RESET = '1') then
			-- add mem reset
		elsif(W_CLK = '1' and W_CLK'event) then
		--	RAM(to_integer(unsigned(R_ADDR(18 downto 10))))(to_integer(unsigned(R_ADDR(9 downto 0))))(3 downto 0)  <= W_R;
		--	RAM(to_integer(unsigned(R_ADDR(18 downto 10))))(to_integer(unsigned(R_ADDR(9 downto 0))))(7 downto 4)  <= W_G;
		--	RAM(to_integer(unsigned(R_ADDR(18 downto 10))))(to_integer(unsigned(R_ADDR(9 downto 0))))(11 downto 8) <= W_B;	
		end if;
	end process WRITE;
end BEHAV;
