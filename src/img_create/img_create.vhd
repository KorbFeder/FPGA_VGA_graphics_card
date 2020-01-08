library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity IMG_CREATE is
	port(W_R, W_G, W_B: out std_logic_vector(3 downto 0);
	     W_ADDR: out std_logic_vector(18 downto 0);
	     SYNC: out std_logic;
		 
	     W_CLK: in std_logic;
	     SYS_CLK: in std_logic;
	     RESET: in std_logic;
		 W_EN: out std_logic);
end IMG_CREATE;

architecture BEHAV of IMG_CREATE is
	--------------------------components------------------------
component charmaps_ROM is
	port (
    i_EN    : in  std_logic;            -- RAM Enable Input
    i_clock : in  std_logic;            -- Clock
    i_ADDR  : in  std_logic_vector(10 downto 0);  -- 11-bit Address Input
    o_DO    : out std_logic_vector(7 downto 0)  -- 8-bit Data Output
	);
end component;

component CLOCK_MACHINE is
  port(CLK: in std_logic;
       RST_GLOBAL: in std_logic;
       SET_SEK: in std_logic;
       SET_MIN: in std_logic;
       SET_HOUR: in std_logic;
       TICK_SEK: out std_logic;
       SEK: out std_logic_vector(5 downto 0);
       MIN: out std_logic_vector(5 downto 0);
       HOUR: out std_logic_vector(5 downto 0));
end component;

component CONVERT
  port(CLK: in std_logic;
       HEX: in std_logic_vector(5 downto 0);
       DIGIT_0: out std_logic_vector(3 downto 0);
       DIGIT_1: out std_logic_vector(3 downto 0));
end component;


-------------------------------------signals-------------

--signals for componet communication
signal RST_GLOBAL: std_logic := '0';													--predefined signals from lcd controller
signal CHAR0, CHAR1, CHAR2, CHAR3: std_logic_vector(7 downto 0);				--char in ascii from clockmachine
signal CHAR4, CHAR5, CHAR6, CHAR7: std_logic_vector(7 downto 0);
signal SEK, MIN, HOUR: std_logic_vector(5 downto 0);
signal MIN_1, MIN_0, SEK_1, SEK_0, HOUR_1, HOUR_0: std_logic_vector(3 downto 0);
signal TICK_SEK: std_logic;
signal Enable: std_logic := '0';										--enable for charmaps_ROM
signal W_CLK2: std_logic:= '0';

---Signals for  process Addr_finding
signal Count_Char: std_logic_vector (2 downto 0) := "000";			-- 8 signs in a row
signal Count_Zeile : std_logic_vector (3 downto 0) := "0000"; 		-- 16 rows
signal Count_Clk: std_logic_vector (2 downto 0) := "000";			-- 8 bit counter to get a slower Clock for address finding
--Signals for process Convert8to1
signal Count_Convert: integer range 0 to 7 := 7; 					-- 8 bit of Data_Input
signal Count_Convert2: std_logic_vector (2 downto 0) := "000";		-- 8 bit of Data_Input but now in verctor for Address 	
signal DATA_Input: std_logic_vector(7 downto 0);					-- 8-bit Data Input from charmaps
signal ADDR: std_logic_vector (10 downto 0);  						-- 11-bit Address Output to charmaps
signal Count_Zeile_write: std_logic_vector (3 downto 0):= "0000";	-- 16 row counter for writing to memory
signal Count_Char_write: std_logic_vector(2 downto 0) := "000";		-- char counter for writing to memory
signal Count_colour: std_logic_vector (1 downto 0) := "00";			-- Counter for different colours
signal W_R_Colour: std_logic_vector (3 downto 0) := "0100";			-- Signal for colour changing
signal W_G_Colour: std_logic_vector (3 downto 0) := "0100";
signal W_B_Colour: std_logic_vector (3 downto 0) := "0100";
--constants for process Addr_finding
--constant OFFSET:  std_logic_vector (10 downto 0) := "01100000000"; 	--Offset wegen charmaps 768 (Sign "0" row 1 starts at address 768)
-- constant for process Convert8to1
constant vOFFSET: std_logic_vector (6 downto 0) := "0111111";		--64
constant hOFFSET: std_logic_vector (8 downto 0) := "100100000";		--288
constant h_max: std_logic_vector (9 downto 0):= "1010000000";		--640


begin

--------------------------port maps------------------------------

	INST_CLOCK_MACHINE: CLOCK_MACHINE
		port map(
				CLK => SYS_CLK,
				RST_GLOBAL => RST_GLOBAL,
				SET_SEK => '0',
				SET_MIN => '0',
				SET_HOUR => '0',
				TICK_SEK => TICK_SEK,
				SEK => SEK,
				MIN => MIN,
				HOUR => HOUR);
  
  	INST_CONV_SEK: CONVERT
		port map(CLK => SYS_CLK,
				HEX => SEK,
				DIGIT_0 => SEK_0 ,
				DIGIT_1 => SEK_1 );
  
  	INST_CONV_MIN: CONVERT
		port map(CLK => SYS_CLK,
				HEX => MIN,
				DIGIT_0 => MIN_0 ,
				DIGIT_1 => MIN_1 );
  
  	INST_CONV_HOUR: CONVERT
		port map(CLK => SYS_CLK,
				HEX => HOUR,
				DIGIT_0 => HOUR_0 ,
				DIGIT_1 => HOUR_1 );

  	INST_charmaps_ROM: charmaps_ROM
		port map (i_clock => W_CLK2,
				i_EN => Enable,
				i_ADDR => ADDR,
				o_DO => DATA_Input );
  
  --convert BCD to ASCII
  CHAR0 <= x"3" & HOUR_1;
  CHAR1 <= x"3" & HOUR_0;
  CHAR2 <= x"3A";         -- colon
  CHAR3 <= x"3" & MIN_1;
  CHAR4 <= x"3" & MIN_0;
  CHAR5 <= x"3A";         -- colon
  CHAR6 <= x"3" & SEK_1;
  CHAR7 <= x"3" & SEK_0;

  --maybe helpful: https://stackoverflow.com/questions/33584342/how-to-add-two-different-sized-vectors-vhdl
-- -------------------process to find the correct address for charmaps ----------------------




Addr_finding: process (W_CLK)
	begin	

		Enable <= '1';
		ADDR <= "00000000000";
		if rising_edge (W_CLK) then --W_CLK = '1' and W_CLK'event 
			Count_Clk <= Count_Clk + 1;
			if Count_Clk = "111" then
				Count_Clk <= "000";
				W_CLK2 <= not W_CLK2;
				case Count_Char is
					when "000" => 
						ADDR <= (CHAR7 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile); 	-- ('0' & Variable) because of different sized vectors
						Count_Char <= "001";
						Enable <= '1';
						
					when "001" => 
						--ADDR <= OFFSET+(CHAR1 (5 downto 0)*"10000")+ Count_Zeile;
						ADDR <= (CHAR6 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						Count_Char <= "010";
						Enable <= '1';
						
					when "010" => 
						ADDR <= (CHAR5 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						Count_Char <= "011";
						Enable <= '1';
						
					when "011" => 
						ADDR <= (CHAR4 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						Count_Char <= "100";
						Enable <= '1';
						
					when "100" => 
						ADDR <= (CHAR3 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						Count_Char <= "101";
						Enable <= '1';
						
					when "101" => 
						ADDR <= (CHAR2 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						Count_Char <= "110";
						Enable <= '1';
						
					when "110" => 
						ADDR <= (CHAR1 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						Count_Char <= "111";
						Enable <= '1';
						
					when "111" => 
						ADDR <= (CHAR0 (5 downto 0)*"10000")+ ("0000000" & Count_Zeile);
						--ADDR <= OFFSET+(SEK_1 *"10000")+ Count_Zeile;
						Count_Char <= "000";
						Enable <= '1';
						Count_Zeile <= Count_Zeile +1;
						if Count_Zeile = "1111" then
							Count_Zeile <= "0000";
						end if;
					when others => ADDR <= "00000000000";
				end case;
			end if;			
		end if;
	end process Addr_finding;


-------------------------State to convert incoming data from charmaps to 12 bit output for Memory -------------------------
--			640
--		-------------------------
--		|			63			|
--		|	288 	|text|	288	|			erste Addresse: 64 * 640 + 288 = 41248
--		|			 			|			
--		|						|	480		zeile 288- 352
--		|			400			|			
--		|						|			vOFFSET = 64
--		|						|			hOFFSET = 288
--		-------------------------			h_max = 640
--


	Convert8to1: process (W_CLK)
	begin	
		W_R <= "0000";
		W_G <= "0000";
		W_B <= "0000";
		W_ADDR <= "0000000000000000000";
		W_EN <= '1';
		if W_CLK = '1' and W_CLK'event then
			if DATA_Input /= x"12" then
			if DATA_Input(Count_Convert) = '1' then
				case Count_colour is
					when "00" => 
						W_B_Colour <= "0100";
						W_G_Colour <= "0100";
						W_R_Colour <= W_R_Colour + "0001";
						if W_R_Colour = "1111" then
							W_R_Colour <=  "0100";
							Count_colour <= Count_colour + "01";
						end if;
					when "01" =>
						W_B_Colour <= "0100";
						W_R_Colour <= "0100";
						W_G_Colour <= W_G_Colour + "0001";
						if W_G_Colour = "1111" then
							W_G_Colour <=  "0100";
							Count_colour <= Count_colour + "01";
						end if;
					when "10" =>
						W_R_Colour <= "0100";
						W_G_Colour <= "0100";
						W_B_Colour <= W_B_Colour + "0001";
						if W_B_Colour = "1111" then
							W_B_Colour <=  "0100";
							Count_colour <= Count_colour + "01";
						end if;
						if Count_colour = "10" then 
							Count_colour <= "00";
						end if;
					when others => 
						W_G_Colour <= "1111";
						if Count_colour = "11" then 
							Count_colour <= "00";
						end if;
					end case;
				W_R <= W_R_Colour;
				W_G <= W_G_Colour;
				W_B <= W_B_Colour;
				W_ADDR <= (vOFFSET * h_max + (("00000" & Count_Zeile_write) * h_max))+ hOFFSET + Count_Convert2 + (Count_Char_write * "1000");	--pixeladdr = vOFFSET+Count_Zeile*(h_max)+hOFFSET+Count_Convert(Count_Char*8) 

			elsif DATA_Input (Count_Convert) = '0' then
				W_R <= "0000";
				W_G <= "0000";
				W_B <= "0000";
				W_ADDR <= (vOFFSET * h_max + (("00000" & Count_Zeile_write) * h_max))+ hOFFSET + Count_Convert2 + (Count_Char_write * "1000");	--pixeladdr = vOFFSET+Count_Zeile*(h_max)+hOFFSET+Count_Convert(Count_Char*8)  
			end if;
			end if;
			Count_Char_write <= Count_Char_write +'1';
			if Count_Convert > 0 then 
				Count_Convert <= Count_Convert - 1; 
			end if;
			Count_Convert2 <= Count_Convert2 + '1';
				
			if Count_Char_write = "111" and Count_Zeile_write = "1111" then
					Sync <= '1';
				else Sync <= '0';
			end if;
			
			if Count_Char_write = "111" then
				Count_Char_write <= "000";
			end if;

			if (Count_Convert = 0) then 
				Count_Convert <= 7;
				Count_Zeile_write <= Count_Zeile_write +'1';
			end if;

			if Count_Convert2 = "111" then 
				Count_Convert2 <= "000";
			end if;

			if Count_Zeile_write = "1111" then
				Count_Zeile_write <= "0000";
			end if;
		end if;

	end process Convert8to1;
end BEHAV;
