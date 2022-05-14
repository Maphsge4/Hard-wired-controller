LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_Arith.ALL;
USE IEEE.STD_LOGIC_Unsigned.ALL;

ENTITY ylx is
	PORT(
		SWB 	: IN   STD_LOGIC; 		--选择不同的控制台模式
		SWA		: IN   STD_LOGIC;		
		SWC		: IN   STD_LOGIC;		
		M   	: OUT  STD_LOGIC;		--M和S用于控制ALU的算术逻辑运算类型
		S   	: OUT  STD_LOGIC_VECTOR(3 DOWNTO 0); --S3,S2,S1,S0	   
		CIN		: OUT  STD_LOGIC;		--进位
		SEL3    : OUT  STD_LOGIC; 		--SEL3SEL2用来选择送往ALU A端口的寄存器，SEL2SEL0用来选择送往ALU B端口的寄存器
		SEL2	: OUT  STD_LOGIC;
		SEL1	: OUT  STD_LOGIC;
		SEL0	: OUT  STD_LOGIC;
		CLR 	: IN   STD_LOGIC;		--复位,低电平有效	
		C		: IN   STD_LOGIC;		--进位标志 
		Z		: IN   STD_LOGIC;		--结果为零标志
		IRH		: IN   STD_LOGIC_VECTOR(3 DOWNTO 0); --IRH7~IRH4，指令操作码
		T3		: IN   STD_LOGIC;		--T3节拍脉冲
		W1		: IN   STD_LOGIC;		--W1节拍电位
		W2		: IN   STD_LOGIC;		--W2节拍电位
		W3  	: IN   STD_LOGIC;		--W3节拍电位
		SELCTL  : OUT  STD_LOGIC;		--为1时处于控制台操作，为0时处于运行程序状态
		DRW    	: OUT  STD_LOGIC;		--为1时在T3上升沿将DBUS上的数据写入SEL3SEL2选中的寄存器
		ABUS 	: OUT  STD_LOGIC;		--为1时运算器结果送数据总线DBUS
		SBUS    : OUT  STD_LOGIC;		--为1时将开关数据送数据总线DBUS
		LIR     : OUT  STD_LOGIC;		--为1时将DBUS上的指令写入AR
		MBUS    : OUT  STD_LOGIC;		--为1时将双端口RAM左端口数据送到DBUS
		MEMW    : OUT  STD_LOGIC;		--为1时在T2为1期间将DBUS写入AR指定的存储器单元，为0时读存储器
		LAR     : OUT  STD_LOGIC;		--为1时在T3的上升沿将DBUS的地址打入AR
		LPC     : OUT  STD_LOGIC; 		--为1时在T3的上升沿将DBUS的数据写入PC
		LDC		: OUT  STD_LOGIC;		--为1时T3的上升沿保存进位
		LDZ     : OUT  STD_LOGIC;		--为1时T3的上升沿保存结果为0标志	
		ARINC   : OUT  STD_LOGIC;		--为1时在T3的上升沿AR加1
		PCINC   : OUT  STD_LOGIC;		--为1时在T3的上升沿PC加1
		PCADD	: OUT  STD_LOGIC;		--PC加上偏移量
		LONG	: OUT  STD_LOGIC;		--标志指令还需要第三个节拍电位W3
		SHORT   : OUT  STD_LOGIC;		--标志指令不需要第二个节拍电位W2
		STOP	: BUFFER STD_LOGIC		--暂停使得可以观察控制台的指示灯等
	);
END ylx;

ARCHITECTURE behavior OF ylx IS
	SIGNAL ST0,SST0:std_logic;
    SIGNAL SWCBA:std_logic_vector(2 DOWNTO 0);
BEGIN
	SWCBA <= SWC & SWB & SWA;
	PROCESS(IRH,ST0,C,Z,W1,W2,W3,SWCBA,CLR,T3)
	BEGIN
	
	IF(CLR='0') THEN
		ST0 <='0';
	ELSIF(T3'EVENT AND T3='0') THEN
		IF(SST0='1') THEN
			ST0 <='1';
		END IF;
		IF(ST0='1' AND W2='1' AND SWCBA="100") THEN
			ST0 <='0';
		END IF;
	END IF;
	
		--给信号设置默认值
		SST0   <='0';
		LDZ	   <='0';
		LDC	   <='0';
		CIN	   <='0';
		S	   <="0000";
		M	   <='0';
		ABUS   <='0';
		DRW	   <='0';
		PCINC  <='0';
		LPC	   <='0';
		LAR	   <='0';
		PCADD  <='0';
		ARINC  <='0';
		SELCTL <='0';
		MEMW   <='0';
		STOP   <='0';
		LIR    <='0';
		SBUS   <='0';
		MBUS   <='0';
		SHORT  <='0';
		LONG   <='0';
		SEL0   <='0';		
		SEL1   <='0';
		SEL2   <='0';
		SEL3   <='0';

		CASE SWCBA IS
			WHEN "100" =>  --写寄存器
				SEL3   <= ST0;
				SEL2   <= W2;
				SEL1   <= (NOT ST0 AND W1) OR (ST0 AND W2);
				SEL0   <= W1;
				SELCTL <= '1';
				SST0   <= (NOT ST0 AND W2);  
				SBUS   <= '1';
				STOP   <= '1';
				DRW    <= '1';
			WHEN "011" => --读寄存器
				SEL3   <= W2;
				SEL2   <= '0';
				SEL1   <= W2;
				SEL0   <= '1';
				SELCTL <= '1';
				STOP   <= '1';
			WHEN "010" => --读存储器
				SBUS   <= NOT ST0 AND W1;
				LAR    <= NOT ST0 AND W1;
				STOP   <= W1;
				SST0   <= NOT ST0 AND W1;
				SHORT  <= W1;
				SELCTL <= W1;
				MBUS   <= ST0 AND W1;
				ARINC  <= W1 AND ST0;
			WHEN "001" => --写存储器
				SELCTL <= W1;
				SST0   <= NOT ST0 AND W1;
				SBUS   <= W1;
				STOP   <= W1;
				LAR    <= NOT ST0 AND W1;
				SHORT  <= W1;
				MEMW   <= ST0 AND W1;
				ARINC  <= ST0 AND W1;
			WHEN "000" => --取值
				SBUS	<=(NOT ST0)AND W1;
				LPC		<=(NOT ST0)AND W1;
				SHORT	<=(NOT ST0)AND W1;
				SST0	<=(NOT ST0)AND W1;
				STOP	<=(NOT ST0)AND W1;
				LIR		<= ST0 AND W1;
				PCINC 	<= ST0 AND W1;
				CASE IRH IS
					WHEN "0001"=> --ADD
						IF(W2='1') THEN
							S    <= "1001";
							CIN  <= '1';
							ABUS <= '1';
							DRW  <= '1';
							LDC  <= '1';
							LDZ  <= '1';
						END IF;
					WHEN "0010"=> --SUB
						IF(W2='1') THEN
							S    <= "0110";
							ABUS <= '1';
							DRW  <= '1';
							LDC  <= '1';
							LDZ  <= '1';
						END IF;
					WHEN "0011"=> --AND
						IF(W2='1') THEN
							M    <= '1';
							S    <= "1011";
							ABUS <= '1';
							DRW  <= '1';
							LDZ  <= '1';
						END IF;
					WHEN "0100"=> --INC
						IF(W2='1') THEN
							S <= "0000";
							ABUS <= '1';
							DRW <= '1';
							LDZ <= '1';
							LDC <= '1';
						END IF;
					WHEN "0101"=> --LD
						IF(W2='1') THEN
							M <= '1';
							S <= "1010";
							ABUS <= '1';
							LAR <= '1';
							LONG <= '1';
						END IF;
						IF(W3='1') THEN
							DRW <= '1';
							MBUS<= '1';	
						END IF;
					WHEN "0110"=> --ST
						IF(W2='1') THEN
							M    <= '1';
							S    <= "1111";
							ABUS <= '1';
							LAR  <= '1';
							LONG <= '1';
						END IF;
						IF(W3='1') THEN
							S    <= "1010";
							M    <='1';
							ABUS <='1';
							MEMW <='1';
						END IF;
					WHEN "0111"=> --JC
						IF(W2='1') THEN
							PCADD <= W2 AND C;
						END IF;
					WHEN "1000"=> --JZ
						IF(W2='1') THEN
							PCADD <= W2 AND Z;
						END IF;
					WHEN "1001"=> --JMP
						IF(W2='1') THEN
							S    <= "1111";
							M    <= '1';
							ABUS <= '1';
							LPC  <= '1';
						END IF;
					WHEN "1010"=> --OUT
						IF(W2='1') THEN
							M<='1';
							S<="1010";
							ABUS<='1';
						END IF;
					WHEN "1011" => --DEC
						CIN <= W2;
						S <= "1111";
						ABUS <= W2;
						DRW <= W2;
						LDC <= W2;
						LDZ <= W2;
					WHEN "1100" => --SHL
						CIN <= W2;
						S <= "1100";
						ABUS <= W2;
						DRW <= W2;
						LDC <= W2;
						LDZ <= W2;
					WHEN "1110"=> --STP
						IF(W2='1') THEN
							STOP<='1';
						END IF;
					WHEN OTHERS => NULL;
				END CASE;
			WHEN OTHERS => NULL;
		END CASE;	
	END PROCESS;
END behavior;