--dichiarazioni delle librerie utilizzate per le operazioni 
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;

--dichiarazione della entity data nella specifica della prova finale
entity project_reti_logiche is
	port (
			i_clk 		: in std_logic;
			i_start 	: in std_logic;
			i_rst 		: in std_logic;
			i_data 		: in std_logic_vector(7 downto 0);
			o_address 	: out std_logic_vector(15 downto 0);
			o_done 		: out std_logic;
			o_en 		: out std_logic;
			o_we 		: out std_logic;
			o_data 		: out std_logic_vector (7 downto 0)
			);
end project_reti_logiche;

architecture project of project_reti_logiche is

    --dichiarazioni di tutti i segnali utilizzati nel codice
    --ogni segnale ha la sua specifica descrizione    
	signal indirizzo       : 	std_logic_vector(15 downto 0) := (others => '0');          --variabile usata per scorrere la memoria RAM              
	signal cMax 		   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la colonna più a destra trovata           
	signal cMin 		   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la colonna più a sinistra trovata
	signal rMax 		   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la riga più in basso trovata
	signal rMin 		   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la riga più in alto trovata
	signal colonne 		   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene il numero di colonne della figura
	signal righe		   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene il numero di righe della figura
	signal soglia		   :	std_logic_vector(7 downto 0) := (others => '0');           --contiene il valore di soglia della figura
	signal area			   :	std_logic_vector(15 downto 0) := (others => '0');	       --contiene il risultato dell'esecuzione
	signal inizio		   :	std_logic := '0';                                          --flag per controllare l'arrivo di i_start
	signal cCorrente	   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la colonna relativa alla cella analizzata
	signal rCorrente	   : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la riga relativa alla cella analizzata
	signal valore	       : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene il valore della cella analizzata
    signal deltaR          : 	std_logic_vector(7 downto 0) := (others => '0');           --contiene la differenza tra rMax e rMin, cioè l'altezza del rettangolo
       
	type stato IS (statoRST, stato0, stato1, stato2, stato3, stato4, statoFinale1, statoFinale2, statoWrite1, statoWrite2, statoFINE);      --dichiarazione di un tipo personalizzato contenente tutti gli stati 
	
	signal stato_corrente : stato;                                                     --stato in cui mi trovo
    signal stato_prossimo : stato;                                                     --stato in cui devo andare
    	
	begin			
	--quando ho gia ricevuto un segnale di start allora enable è 1 per poter leggere la memoria
	o_en <= '1' when inizio = '1' else '0';
	
	--write enable è a 1 solo quando devo effettivamente scrivere in memoria, cioè in Write1 e in Write2 
	o_we <= '1' when stato_corrente = statoWrite1 or stato_corrente = statoWrite2 else '0';	
	
	--istruzione per modificare l'indirizzo della memoria
	o_address <= indirizzo;
		
		--funzione dello stato corrente
		current_state_output_process: process(i_clk, stato_corrente, i_rst)		
		variable controllo	: 	std_logic_vector(7 downto 0) := (others => '0');	--variabile usata per capire in quale riga e in quale colonna si trova la cella analizzata
		begin
		
		if i_rst = '1' then
            stato_prossimo <= statoRST;		--quando arriva un segnale di reset devo cambiare lo stato prossimo e impostarlo allo stato di reset
        end if;
		
		if(rising_edge(i_clk)) then		    --controllo necessario per sincronizzare l'esecuzione con un fronte di salita del clock
		
		case stato_corrente is              --in base a quale stato sto considerando ho diverse azioni 
			--stato in cui vado nel caso di Reset, rimango qua fino a quando start ritorna a 1
			when statoRST =>                                
				if (inizio = '1') then
					stato_prossimo <= stato0;
				else 
					stato_prossimo <= statoRST;
                end if;
			 
			--stato iniziale
			when stato0 =>
				--inizializzo solo: indirizzo, controllo, rCorrente, deltaR
				--perchè sono quelle che hanno un espressione tipo a=a+1, potrebbero creare problemi	
				--l'area però viene già posta a zero dopo
				indirizzo <= (1 => '1', others => '0');
				controllo := (others => '0');
				rCorrente <= (others => '0');
				deltaR <= (others => '0');
				stato_prossimo <= stato1;						
					
			--stato in cui leggo le colonne e aggiorno l'indirizzo
			when stato1 =>
				colonne <= i_data;
				indirizzo <= (0 => '1', 1 => '1', others => '0');
				stato_prossimo <= stato2;
						
			--stato in cui leggo le righe e aggiorno l'indirizzo	
			when stato2 =>
				righe <= i_data;
				cMin <= colonne - '1';                              --inizializzo cMin
				indirizzo <= (2 => '1', others => '0');
				stato_prossimo <= stato3;
				
			--stato in cui leggo la soglia e aggiorno l'indirizzo			
            when stato3 =>
				soglia <= i_data;
                rMin <= righe - '1';                                --inizializzo rMin
                indirizzo <= (0 => '1', 2 => '1', others => '0');
                stato_prossimo <= stato4;                
				
			--inizio a leggere immagine
            when stato4 =>                        
				valore <= i_data;
                indirizzo <= indirizzo + '1';
                
				--controllo se ho finito l'immagine o se devo leggere ancora dalla memoria          
                if (rCorrente = righe) then
					stato_prossimo <= statoFinale1;
                else 
					stato_prossimo <= stato4;
                                       
					--controllo per capire in quale riga sono
					if(controllo = colonne) then                        --se questo si verifica vuol dire che sono già su una nuova riga
						rCorrente <= rCorrente + '1';                   --allora aumento la riga corrente
						controllo := (others => '0');                   --e metto a 0 la variabile di controllo
					end if;
					cCorrente <= controllo;                             --in ogni caso la colonna in cui sono è data dalla varibile di controllo
					controllo := controllo + '1';                       --aumento già la variabile per il ciclo successivo
                        
					--controllo se ho un valore significativo
					if(valore >= soglia) then                        
					--calcolo colonne estreme
						if(cCorrente > cMax) then
							cMax <= cCorrente;
						end if;
						if(cCorrente < cMin) then
							cMin <= cCorrente;
						end if;                           
						--calcolo righe estreme
						if(rCorrente > rMax) then
							rMax <= rCorrente;
						end if;
						if(rCorrente < rMin) then
							rMin <= rCorrente;
						end if;
					end if;                        
				end if;
                
				--stato in cui decido se l'area rimane a 0 o se devo calcolarla 
            when statoFinale1 => --PROVARE A ELIMINARE QUESTO STATO
				area <= (others => '0');
                        
                --controllo se i valori estremi sono stati modificati                                                                       
                if(cMin > cMax or rMin > rMax) then
					stato_prossimo <= statoWrite1;                            
                else
					--in questo caso calcolo l'altezza del rettangolo, mentre la base viene fatta dopo
					deltaR <= rMax - rMin + '1';
                    stato_prossimo <= statoFinale2;
                end if;
                        
            --stato in cui calcolo effettivamente l'area del rettangolo
            when statoFinale2 =>
				if(deltaR = 0) then                                --se ho finito l'iterazione passo allo stato di scrittura
					stato_prossimo <= statoWrite1;
                else
					--altrimenti calcolo l'area                                                
                    area <= area + cMax - cMin + '1';
                    deltaR <= deltaR - '1';
                    stato_prossimo <= statoFinale2; 
                end if;        
                        
            --primo stato per la scrittura della parte meno significativa        
            when statoWrite1 =>
                --scrivo la parte meno significativa e cambio indirizzo
                indirizzo <= (others => '0');                               
                o_data <= area(7 downto 0);
                stato_prossimo <= statoWrite2;
                        
            --secondo stato per la scrittura della parte più significativa   
            when statoWrite2 =>
                --scrivo l'ultima parte e metto done a 1 
                indirizzo <= (0 => '1', others => '0');           
                o_data <= area(15 downto 8);                        
                --segnalo la fine del programma
                o_done <= '1';                        
                stato_prossimo <= statoFINE;
                
            --stato che termina realmente il programma, mettendo done a 0
            when statoFINE =>
                o_done <= '0';
                               
			when others => stato_prossimo <= statoRST;
				
		end case;
		end if;
		end process;
		
		--funzione di switch e reset degli stati
		next_state_process: process(i_clk)
        begin
		--ad ogni ciclo di clock aggiorno lo stato corrente in base allo stato prossimo definito
        if rising_edge(i_clk) then                
            stato_corrente <= stato_prossimo;
        end if;
		
        end process;  
        
        p1: process(i_rst,i_start)
        begin
		--se arriva il segnale di start metto il segnale inizio a 1, così può procedere l'elaborazione
        if i_start = '1' then
            inizio <= '1';
        end if; 
		--se arriva il segnale di reset metto il segnale inizio a 0, così fermo l'elaborazione
        if i_rst = '1' then
            inizio <= '0';
        end if;   
		
        end process;
		
end project;
