library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity esteira_rolante is
	port(
		clock_50MHz, reset, dir, sensor: in std_logic;											-- Entradas
		bobinas: out std_logic_vector(3 downto 0)); 												-- Saídas
end esteira_rolante;

architecture behav of esteira_rolante is
			type estado is (S0, S1, S2, S3);
			signal estado_presente, proximo_estado: estado; 									-- Estados do motor de passo (motor da esteira rolante)
			signal clk_passo: std_logic; 																-- Status para uso nos estados do motor
			signal contagem_ativa, clock_1Hz: std_logic; 										-- Clock que informa para dar 1 "passo"
			signal divisor: unsigned(22 downto 0) := "00000000000000000000000"; 			-- Clock de utilizado para fazer a contagem após a escada desativar
			signal u_s: unsigned (3 downto 0):=(others => '0');
			signal divisor_timer: unsigned(24 downto 0):="0000000000000000000000000";
			
begin 

	div_clock: process (clock_50MHz)
	
		variable pulso: std_logic;
		variable tic_half_period: std_logic;
		
	begin
		if(clock_50MHz='1' and clock_50MHz'event)then
			divisor_timer <= divisor_timer +1;
			if(sensor = '1' or contagem_ativa = '1')then
				divisor <= divisor + 1;
				
				if divisor = "000010100101101000000" then  										-- 84800 = 294[Hz]  Alta velocidade
					pulso := NOT pulso;
					divisor <= (others=> '0');
				end if;
				
			elsif(sensor = '0' and contagem_ativa = '0')then
				divisor <= divisor + 1;
				
				if divisor = "0100000100101101000000" then									   --1067840 = 234[Hz]  Baixa velocidade
					pulso := NOT pulso;
					divisor <= (others=> '0');
				end if;
				
			end if;
			if(divisor_timer="1011111010111100001000000") then									--25000000 = 1[Hz]  Contador de Tempo
				tic_half_period := NOT tic_half_period;
				divisor_timer <= (others => '0');
         end if;
		end if;	
		clk_passo <= pulso;         	                              
      clock_1Hz <= tic_half_period;	
	end process;         	
	  
	  -- "Pulso" controla a velocidade do motor de passo
	  
	contagem: process (clock_1Hz)
	begin
		if(sensor = '1')then
			contagem_ativa <= '1';
			u_s <= "0000";
		else
			if(rising_edge(clock_1Hz))then
				u_s <= u_s + 1;
					if (u_s = "1001") then																-- 9  Contagem até 10 para desacionar a alta velocidade 
						u_s <= "0000";
						contagem_ativa <= '0';
					end if;
			end if;
		end if;
	end process;
	
	
		
	sequencial: process (reset, clk_passo)
	begin
		if(reset = '1') then
			estado_presente <= S0;
		elsif (rising_edge(clk_passo)) then
			estado_presente <= proximo_estado;
		end if;
	end process;
	
	
	
	combinacional: process (estado_presente)
	begin
		case estado_presente is
			when S0 =>
				bobinas <= "0001";
				if(dir = '1') then
					proximo_estado <= S1;
				else
					proximo_estado <= S3;
				end if;
			when S1 =>
				bobinas <= "0010";
				if(dir = '1') then
					proximo_estado <= S2;
				else
					proximo_estado <= S0;
				end if;
			when S2 =>
				bobinas <= "0100";
				if(dir = '1') then
					proximo_estado <= S3;
				else
					proximo_estado <= S1;
				end if;
			when S3 =>
				bobinas <= "1000";
				if(dir = '1') then
					proximo_estado <= S0;
				else
					proximo_estado <= S2;
				end if;
		end case;
	end process;
end behav;