library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WAIT_TIMER is
	generic(INT_RANGE: integer);
	port(
		CLK, RESET: in std_logic;
		Q: out integer range 0 to INT_RANGE);
end WAIT_TIMER;

architecture BEHAV of WAIT_TIMER is
	signal CNT: integer range 0 to INT_RANGE := 0;
begin
	process(CLK, RESET)  
		begin
			if RESET='1' then
				CNT<= 0;      
			end if;
			if (CLK='1' and CLK'event) then
				CNT<= CNT+1;
			end if;
	end process;
	Q <= CNT;
end BEHAV;
