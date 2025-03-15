`include "elevador1.sv"
`include "elevador2.sv"
`include "elevador3.sv"
`include "modulosAux.sv"

module tb_controle;
  reg RESET, CLOCK;
  reg I1, I2, I3, I4, I5, E1, E2, E3, E4, E5, S1, S2, S3, S4, S5, S1_SQ, S2_SQ, S3_SQ, S4_SQ, S5_SQ;
  reg [2:0] lista_chamadas_cenario1 [0:2];
  wire  [31:0] SAIDA, SAIDA_MOD_REF;
  wire [31:0] ESTADO_MOTOR;
  wire [31:0] PAVIMENTO, PAVIMENTO_REF;
  wire [5-1:0] ESTADO;
  wire PORT1, PORT2, PORT3, PORT4, PORT5, PORT1_MOD_REF, PORT2_MOD_REF, PORT3_MOD_REF, PORT4_MOD_REF, PORT5_MOD_REF, CLOCK_DIV;
  
  reg [1:0] SAIDA_CONV, SAIDA_CONV_MOD_REF;
  
  parameter TEMPO_ENTRE_PAVIMENTOS = 250;
  parameter TEMPO_VERIFICACAO = 50;
 
  int tempo_requisicao;						// Variável que armazena o tempo gerado randomicamente entre as chamadas (1 - 600)
  int gerar_clock_random;					// Variável que determina o momento de geração de mais um tempo randomico
  int andar;								// Variável que armazena o andar randomico a ser chamado (1 - 5)
  int count_clock;							// Variável para contar o pulso de clock
  int chamada_interna_externa;				// Variável que define se a chamada será interna ou externa
  int count_porta;
  int count_verificar_portas;
  int count_para_sensores;
  
  //int i;
  logic [4:0] chamadas_mod_ref;				// Armazena as chamadas ativas dos pavimentos
  
  logic [4:0] atendimento_lista[$];
  logic [4:0] atendimento_mod_ref_lista[$];
  
  logic [4:0] motor_lista[$];
  logic [4:0] motor_ref_lista[$];
  
  logic [4:0] porta_lista[$];
  logic [4:0] porta_mod_ref_lista[$];  
  
  /************************************ ATRIBUIÇÕES *************************************/

  // Atribuição de variavel para os pavimentos do Modelo de Referência
  
  logic [4:0] pavimentos_elev;
  assign pavimentos_elev[0] = S1;
  assign pavimentos_elev[1] = S2;
  assign pavimentos_elev[2] = S3;
  assign pavimentos_elev[3] = S4;
  assign pavimentos_elev[4] = S5;
  
  logic[4:0] pavimentos_mod_ref;
  assign pavimentos_mod_ref[0] = S1_SQ;
  assign pavimentos_mod_ref[1] = S2_SQ;
  assign pavimentos_mod_ref[2] = S3_SQ;
  assign pavimentos_mod_ref[3] = S4_SQ;
  assign pavimentos_mod_ref[4] = S5_SQ;

  logic[4:0] portas_elev;
  assign portas_elev[0] = PORT1;
  assign portas_elev[1] = PORT2;
  assign portas_elev[2] = PORT3;
  assign portas_elev[3] = PORT4;
  assign portas_elev[4] = PORT5;

  logic[4:0] portas_mod_ref;
  assign portas_mod_ref[0] = PORT1_MOD_REF;
  assign portas_mod_ref[1] = PORT2_MOD_REF;
  assign portas_mod_ref[2] = PORT3_MOD_REF;
  assign portas_mod_ref[3] = PORT4_MOD_REF;
  assign portas_mod_ref[4] = PORT5_MOD_REF;

  // Atribuição de variavel aos botões externos
  logic [4:0] botoes_externos;
  assign E1 = botoes_externos[0];
  assign E2 = botoes_externos[1];
  assign E3 = botoes_externos[2];
  assign E4 = botoes_externos[3];
  assign E5 = botoes_externos[4];
  
  // Atribuição de variavel aos botões internos
  logic [4:0] botoes_internos;
  assign I1 = botoes_internos[0];
  assign I2 = botoes_internos[1];
  assign I3 = botoes_internos[2];
  assign I4 = botoes_internos[3];
  assign I5 = botoes_internos[4];
  
  // Atribuição da variavel 'sequencia_atendimento' que armazena todas as informações pertinentes na análise do funcionamento de um elevador
  logic [11:0] sequencia_atendimento;
  assign sequencia_atendimento[11] = S1_SQ;				// Sensor do primeiro pavimento
  assign sequencia_atendimento[10] = S2_SQ;				// Sensor do segundo pavimento
  assign sequencia_atendimento[9] = S3_SQ;				// Sensor do terceiro pavimento
  assign sequencia_atendimento[8] = S4_SQ;				// Sensor do quarto pavimento
  assign sequencia_atendimento[7] = S5_SQ;				// Sensor do quinto pavimento
  assign sequencia_atendimento[6] = SAIDA_CONV_MOD_REF[1];		// Segundo bit do sentido motor
  assign sequencia_atendimento[5] = SAIDA_CONV_MOD_REF[0];		// Primeiro bit do sentido motor
  assign sequencia_atendimento[4] = PORT1_MOD_REF;				// Porta do primeiro pavimento
  assign sequencia_atendimento[3] = PORT2_MOD_REF;				// Porta do segundo pavimento
  assign sequencia_atendimento[2] = PORT3_MOD_REF;				// Porta do terceiro pavimento
  assign sequencia_atendimento[1] = PORT4_MOD_REF;				// Porta do quarto pavimento
  assign sequencia_atendimento[0] = PORT5_MOD_REF;				// Porta do quinto pavimento
  
  /**************************************************************************************/
  
  /************************************* INSTÂNCIAS *************************************/
  
  // Instância do módulo do sequenciador de pavimentos

  seq_pavimento seq(
    .clk(CLOCK),
    .rst(RESET),
    .motor(SAIDA_CONV),
    .s1(S1),
    .s2(S2),
    .s3(S3),
    .s4(S4),
    .s5(S5)
  );

  seq_pavimento seq_mod_ref(
    .clk(CLOCK),
    .rst(RESET),
    .motor(SAIDA_CONV_MOD_REF),
    .s1(S1_SQ),
    .s2(S2_SQ),
    .s3(S3_SQ),
    .s4(S4_SQ),
    .s5(S5_SQ)
  );
  
  // Instância do módulo do conversor de saída do modelo de referência
  conv_saida saida_convertida_mod_ref(
    .reset(RESET),
    .entrada(SAIDA_MOD_REF),
    .saida(SAIDA_CONV_MOD_REF)  
  );
  
  // Instância do módulo do conversor de saída DO ELEVADOR
  conv_saida saida_convertida(
    .reset(RESET),
    .entrada(SAIDA),
    .saida(SAIDA_CONV)  
  );
  
  // Instância do módulo do Modelo de Refêrencia 
  mod_ref uut (
    .reset(RESET),
    .clock(CLOCK),
    .bi1(I1),
    .bi2(I2),
    .bi3(I3),
    .bi4(I4),
    .bi5(I5),
    .be1(E1),
    .be2(E2),
    .be3(E3),
    .be4(E4),
    .be5(E5),
    .s1(S1_SQ),
    .s2(S2_SQ),
    .s3(S3_SQ),
    .s4(S4_SQ),
    .s5(S5_SQ),
    .Port1(PORT1_MOD_REF),
    .Port2(PORT2_MOD_REF),
    .Port3(PORT3_MOD_REF),
    .Port4(PORT4_MOD_REF),
    .Port5(PORT5_MOD_REF),
    .saida(SAIDA_MOD_REF),
    .pavimento(PAVIMENTO_REF)
  );
  
  //Instâna do módulo do Elevador
  elevador3 elev1 (
    .reset(RESET),
    .clock(CLOCK),
    .bi1(I1),
    .bi2(I2),
    .bi3(I3),
    .bi4(I4),
    .bi5(I5),
    .be1(E1),
    .be2(E2),
    .be3(E3),
    .be4(E4),
    .be5(E5),
    .s1(S1),
    .s2(S2),
    .s3(S3),
    .s4(S4),
    .s5(S5),
    .Port1(PORT1),
    .Port2(PORT2),
    .Port3(PORT3),
    .Port4(PORT4),
    .Port5(PORT5),
    .saida(SAIDA),
    .pavimento(PAVIMENTO)
  );
  
  /**************************************************************************************/
  
  /************************************* COBERTURAS *************************************/
  
// Criação das coberturas dos pavimento que representam o funcionamento comum do elevador, assegurando que todos os estados ocorreram com êxito. Cada cobertura individualmente representará todas as interações possíveis entre um pavimento com os demais.
  
//Covergroup para o 1 pavimento
covergroup CG_pavimento1 @(sequencia_atendimento);
  coverpoint sequencia_atendimento{
    
    // Interação do primeiro pavimento para o primeiro
    bins P1_para_P1_1 = (12'b100000000000 => 12'b100000010000) iff(chamadas_mod_ref[0]); 	// S1 => Abre PORT1 
    bins P1_para_P1_2 = (12'b100000010000 => 12'b100000000000) iff(chamadas_mod_ref[0]); 	// Abre PORT1 => Fecha PORT1
    
    // Interação do primeiro pavimento para o segundo
    bins P1_para_P2_1 = (12'b100000000000 => 12'b100000100000) iff(chamadas_mod_ref[1]); 	// S1 => Ativa motor
    bins P1_para_P2_2 = (12'b100000100000 => 12'b000000100000) iff(chamadas_mod_ref[1]); 	// Ativa motor => Estado transição
    bins P1_para_P2_3 = (12'b000000100000 => 12'b010000100000) iff(chamadas_mod_ref[1]); 	// Estado transição => S2
    bins P1_para_P2_4 = (12'b010000100000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// S2 => Desativa motor
    bins P1_para_P2_5 = (12'b010000000000 => 12'b010000001000) iff(chamadas_mod_ref[1]); 	// Desativa motor => Abre PORT2
    bins P1_para_P2_6 = (12'b010000001000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// Abre PORT2 => Fecha PORT2
    
  	// Interação do primeiro pavimento para o terceiro
    bins P1_para_P3_1 = (12'b100000000000 => 12'b100000100000) iff(chamadas_mod_ref[2]); 	// S1 => Ativa motor
    bins P1_para_P3_2 = (12'b100000100000 => 12'b000000100000) iff(chamadas_mod_ref[2]); 	// Ativa motor => Estado transição
    bins P1_para_P3_3 = (12'b000000100000 => 12'b010000100000) iff(chamadas_mod_ref[2]); 	// Estado transição => S2
    bins P1_para_P3_4 = (12'b010000100000 => 12'b000000100000) iff(chamadas_mod_ref[2]); 	// S2 => Estado transição
    bins P1_para_P3_5 = (12'b000000100000 => 12'b001000100000) iff(chamadas_mod_ref[2]); 	// Estado transição => S3
    bins P1_para_P3_6 = (12'b001000100000 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// S3 => Desativa motor
    bins P1_para_P3_7 = (12'b001000000000 => 12'b001000000100) iff(chamadas_mod_ref[2]); 	// Desativa motor => Abre PORT3
    bins P1_para_P3_8 = (12'b001000000100 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// Abre PORT3 => Fecha PORT3
    
    // Interação do primeiro pavimento para o quarto
    bins P1_para_P4_1 = (12'b100000000000 => 12'b100000100000) iff(chamadas_mod_ref[3]); 	// S1 => Ativa motor
    bins P1_para_P4_2 = (12'b100000100000 => 12'b000000100000) iff(chamadas_mod_ref[3]); 	// Ativa motor => Estado transição
    bins P1_para_P4_3 = (12'b000000100000 => 12'b010000100000) iff(chamadas_mod_ref[3]); 	// Estado transição => S2
    bins P1_para_P4_4 = (12'b010000100000 => 12'b000000100000) iff(chamadas_mod_ref[3]); 	// S2 => Estado transição
    bins P1_para_P4_5 = (12'b000000100000 => 12'b001000100000) iff(chamadas_mod_ref[3]); 	// Estado transição => S3
    bins P1_para_P4_6 = (12'b001000100000 => 12'b000000100000) iff(chamadas_mod_ref[3]); 	// S3 => Estado transição
    bins P1_para_P4_7 = (12'b000000100000 => 12'b000100100000) iff(chamadas_mod_ref[3]); 	// Estado transição => S4
    bins P1_para_P4_8 = (12'b000100100000 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// S4 => Desativa motor
    bins P1_para_P4_9 = (12'b000100000000 => 12'b000100000010) iff(chamadas_mod_ref[3]); 	// Desativa motor => Abre PORT4
    bins P1_para_P4_10 = (12'b000100000010 => 12'b000100000000) iff(chamadas_mod_ref[3]); // Abre PORT4 => Fecha PORT4
    
    // Interação do primeiro pavimento para o quinto
    bins P1_para_P5_1 = (12'b100000000000 => 12'b100000100000) iff(chamadas_mod_ref[4]); 	// S1 => Ativa motor
    bins P1_parP2_para_P= (12'b100000100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// Ativa motor => Estado transição
    bins P1_para_P5_3 = (12'b000000100000 => 12'b010000100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S2
    bins P1_para_P5_4 = (12'b010000100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// S2 => Estado transição
    bins P1_para_P5_5 = (12'b000000100000 => 12'b001000100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S3
    bins P1_para_P5_6 = (12'b001000100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// S3 => Estado transição
    bins P1_para_P5_7 = (12'b000000100000 => 12'b000100100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S4
    bins P1_para_P5_8 = (12'b000100100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// S4 => Estado transição
    bins P1_para_P5_9 = (12'b000000100000 => 12'b000010100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S5
    bins P1_para_P5_10 = (12'b000010100000 => 12'b000010000000) iff(chamadas_mod_ref[4]); // S5 => Desativa motor
    bins P1_para_P5_11 = (12'b000010000000 => 12'b000010000001) iff(chamadas_mod_ref[4]); // Desativa motor => Abre PORT5
    bins P1_para_P5_12 = (12'b000010000001 => 12'b000010000000) iff(chamadas_mod_ref[4]); // Abre PORT5 => Fecha PORT5
  } 
  endgroup
  
//Covergroup para o 2 pavimento
covergroup CG_pavimento2 @(sequencia_atendimento);
coverpoint sequencia_atendimento{
  
    // Interação do segundo pavimento para o segundo
  	bins P2_para_P2_1 = (12'b010000000000 => 12'b010000001000) iff(chamadas_mod_ref[1]); 	// S2 => Abre PORT2 
    bins P2_para_P2_2 = (12'b010000001000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// Abre PORT2 => Fecha PORT2

    // Interação do segundo pavimento para o primeiro
  	bins P2_para_P1_1 = (12'b010000000000 => 12'b010001000000) iff(chamadas_mod_ref[0]); 	// S2 => Ativa motor
    bins P2_para_P1_2 = (12'b010001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// Ativa motor => Estado transição
    bins P2_para_P1_3 = (12'b000001000000 => 12'b100001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S1
  	bins P2_para_P1_4 = (12'b100001000000 => 12'b100000000000) iff(chamadas_mod_ref[0]); 	// S1 => Desativa motor
    bins P2_para_P1_5 = (12'b100000000000 => 12'b100000010000) iff(chamadas_mod_ref[0]); 	// Desativa motor => Abre PORT1
    bins P2_para_P1_6 = (12'b100000010000 => 12'b100000000000) iff(chamadas_mod_ref[0]); 	// Abre PORT1 => Fecha PORT1

    // Interação do segundo pavimento para o terceiro
    bins P2_para_P3_1 = (12'b010000000000 => 12'b010000100000) iff(chamadas_mod_ref[2]); 	// S2 => Ativa motor
    bins P2_para_P3_2 = (12'b010000100000 => 12'b000000100000) iff(chamadas_mod_ref[2]); 	// Ativa motor => Estado transição
    bins P2_para_P3_3 = (12'b000000100000 => 12'b001000100000) iff(chamadas_mod_ref[2]); 	// Estado transição => S3
  	bins P2_para_P3_4 = (12'b001000100000 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// S3 => Desativa motor
    bins P2_para_P3_5 = (12'b001000000000 => 12'b001000000100) iff(chamadas_mod_ref[2]); 	// Desativa motor => Abre PORT3
    bins P2_para_P3_6 = (12'b001000000100 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// Abre PORT3 => Fecha PORT3

    // Interação do segundo pavimento para o quarto
    bins P2_para_P4_1 = (12'b010000000000 => 12'b010000100000) iff(chamadas_mod_ref[3]); 	// S2 => Ativa motor
    bins P2_para_P4_2 = (12'b010000100000 => 12'b000000100000) iff(chamadas_mod_ref[3]); 	// Ativa motor => Estado transição
    bins P2_para_P4_3 = (12'b000000100000 => 12'b001000100000) iff(chamadas_mod_ref[3]); 	// Estado transição => S3
  	bins P2_para_P4_4 = (12'b001000100000 => 12'b000000100000) iff(chamadas_mod_ref[3]); 	// S3 => Estado transição
    bins P2_para_P4_5 = (12'b000000100000 => 12'b000100100000) iff(chamadas_mod_ref[3]); 	// Estado transição => S4
  	bins P2_para_P4_6 = (12'b000100100000 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// S4 => Desativa motor
    bins P2_para_P4_7 = (12'b000100000000 => 12'b000100000010) iff(chamadas_mod_ref[3]); 	// Desativa motor => Abre PORT4
    bins P2_para_P4_8 = (12'b000100000010 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// Abre PORT4 => Fecha PORT4

    // Interação do segundo pavimento para o quinto
    bins P2_para_P5_1 = (12'b010000000000 => 12'b010000100000) iff(chamadas_mod_ref[4]); 	// S2 => Ativa motor
    bins P2_para_P5_2 = (12'b010000100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// Ativa motor => Estado transição
    bins P2_para_P5_3 = (12'b000000100000 => 12'b001000100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S3
    bins P2_para_P5_4 = (12'b001000100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// S3 => Estado transição
    bins P2_para_P5_5 = (12'b000000100000 => 12'b000100100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S4
  	bins P2_para_P5_6 = (12'b000100100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// S4 => Estado transição
    bins P2_para_P5_7 = (12'b000000100000 => 12'b000010100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S5
  	bins P2_para_P5_8 = (12'b000010100000 => 12'b000010000000) iff(chamadas_mod_ref[4]); 	// S5 => Desativa motor
    bins P2_para_P5_9 = (12'b000010000000 => 12'b000010000001) iff(chamadas_mod_ref[4]); 	// Desativa motor => Abre PORT5
    bins P2_para_P5_10 = (12'b000010000001 => 12'b000010000000) iff(chamadas_mod_ref[4]); // Abre PORT5 => Fecha PORT5
}
  endgroup

//Covergroup para o 3 pavimento
covergroup CG_pavimento3 @(sequencia_atendimento);
coverpoint sequencia_atendimento{
  
    // Interação do terceiro pavimento para o terceiro
  	bins P3_para_P3_1 = (12'b001000000000 => 12'b001000000100) iff(chamadas_mod_ref[2]); 	// S3 => Abre PORT3 
    bins P3_para_P3_2 = (12'b001000000100 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// Abre PORT3 => Fecha PORT3

    // Interação do terceiro pavimento para o segundo
  	bins P3_para_P2_1 = (12'b001000000000 => 12'b001001000000) iff(chamadas_mod_ref[1]); 	// S3 => Ativa motor
    bins P3_para_P2_2 = (12'b001001000000 => 12'b000001000000) iff(chamadas_mod_ref[1]); 	// Ativa motor => Estado transição
    bins P3_para_P2_3 = (12'b000001000000 => 12'b010001000000) iff(chamadas_mod_ref[1]); 	// Estado transição => S2
  	bins P3_para_P2_4 = (12'b010001000000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// S2 => Desativa motor
    bins P3_para_P2_5 = (12'b010000000000 => 12'b010000001000) iff(chamadas_mod_ref[1]); 	// Desativa motor => Abre PORT2
    bins P3_para_P2_6 = (12'b010000001000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// Abre PORT2 => Fecha PORT2

    // Interação do terceiro pavimento para o primeiro
    bins P3_para_P1_1 = (12'b001000000000 => 12'b001001000000) iff(chamadas_mod_ref[0]); 	// S3 => Ativa motor
    bins P3_para_P1_2 = (12'b001001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// Ativa motor => Estado transição
    bins P3_para_P1_3 = (12'b000001000000 => 12'b010001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S2
  	bins P3_para_P1_4 = (12'b010001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// S2 => Estado transição
    bins P3_para_P1_5 = (12'b000001000000 => 12'b100001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S1
  	bins P3_para_P1_6 = (12'b100001000000 => 12'b100000000000) iff(chamadas_mod_ref[0]); 	// S1 => Desativa motor
    bins P3_para_P1_7 = (12'b100000000000 => 12'b100000010000) iff(chamadas_mod_ref[0]); 	// Desativa motor => Abre PORT1
    bins P3_para_P1_8 = (12'b100000010000 => 12'b100000000000) iff(chamadas_mod_ref[0]); 	// Abre PORT1 => Fecha PORT1

    // Interação do terceiro pavimento para o quarto
    bins P3_para_P4_1 = (12'b001000000000 => 12'b001000100000) iff(chamadas_mod_ref[3]); 	// S3 => Ativa motor
    bins P3_para_P4_2 = (12'b001000100000 => 12'b000000100000) iff(chamadas_mod_ref[3]); 	// Ativa motor => Estado transição
    bins P3_para_P4_3 = (12'b000000100000 => 12'b000100100000) iff(chamadas_mod_ref[3]); 	// Estado transição => S4
  	bins P3_para_P4_4 = (12'b000100100000 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// S4 => Desativa motor
    bins P3_para_P4_5 = (12'b000100000000 => 12'b000100000010) iff(chamadas_mod_ref[3]); 	// Desativa motor => Abre PORT4
    bins P3_para_P4_6 = (12'b000100000010 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// Abre PORT4 => Fecha PORT4

    // Interação do terceiro pavimento para o quinto
    bins P3_para_P5_1 = (12'b001000000000 => 12'b001000100000) iff(chamadas_mod_ref[4]); 	// S3 => Ativa motor
    bins P3_para_P5_2 = (12'b001000100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// Ativa motor => Estado transição
    bins P3_para_P5_3 = (12'b000000100000 => 12'b000100100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S4
  	bins P3_para_P5_4 = (12'b000100100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// S4 => Estado transição
    bins P3_para_P5_5 = (12'b000000100000 => 12'b000010100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S5
  	bins P3_para_P5_6 = (12'b000010100000 => 12'b000010000000) iff(chamadas_mod_ref[4]); 	// S5 => Desativa motor
    bins P3_para_P5_7 = (12'b000010000000 => 12'b000010000001) iff(chamadas_mod_ref[4]); 	// Desativa motor => Abre PORT5
    bins P3_para_P5_8 = (12'b000010000001 => 12'b000010000000) iff(chamadas_mod_ref[4]); 	// Abre PORT5 => Fecha PORT5
}
  endgroup

//Covergroup para o 4 pavimento
covergroup CG_pavimento4 @(sequencia_atendimento);
coverpoint sequencia_atendimento{
  
    // Interação do quarto pavimento para o quarto
  	bins P4_para_P4_1 = (12'b000100000000 => 12'b000100000010) iff(chamadas_mod_ref[3]); 	// S4 => Abre PORT4 
    bins P4_para_P4_2 = (12'b000100000010 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// Abre PORT4 => Fecha PORT4

    // Interação do quarto pavimento para o terceiro
  	bins P4_para_P3_1 = (12'b000100000000 => 12'b000101000000) iff(chamadas_mod_ref[2]); 	// S4 => Ativa motor
    bins P4_para_P3_2 = (12'b000101000000 => 12'b000001000000) iff(chamadas_mod_ref[2]); 	// Ativa motor => Estado transição
    bins P4_para_P3_3 = (12'b000001000000 => 12'b001001000000) iff(chamadas_mod_ref[2]); 	// Estado transição => S3
  	bins P4_para_P3_4 = (12'b001001000000 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// S3 => Desativa motor
    bins P4_para_P3_5 = (12'b001000000000 => 12'b001000000100) iff(chamadas_mod_ref[2]); 	// Desativa motor => Abre PORT3
    bins P4_para_P3_6 = (12'b001000000100 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// Abre PORT3 => Fecha PORT3

    // Interação do quarto pavimento para o segundo
    bins P4_para_P2_1 = (12'b000100000000 => 12'b000101000000) iff(chamadas_mod_ref[1]); 	// S4 => Ativa motor
    bins P4_para_P2_2 = (12'b000101000000 => 12'b000001000000) iff(chamadas_mod_ref[1]); 	// Ativa motor => Estado transição
    bins P4_para_P2_3 = (12'b000001000000 => 12'b001001000000) iff(chamadas_mod_ref[1]); 	// Estado transição => S3
  	bins P4_para_P2_4 = (12'b001001000000 => 12'b000001000000) iff(chamadas_mod_ref[1]); 	// S3 => Estado transição
    bins P4_para_P2_5 = (12'b000001000000 => 12'b010001000000) iff(chamadas_mod_ref[1]); 	// Estado transição => S2
  	bins P4_para_P2_6 = (12'b010001000000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// S2 => Desativa motor
    bins P4_para_P2_7 = (12'b010000000000 => 12'b010000001000) iff(chamadas_mod_ref[1]); 	// Desativa motor => Abre PORT2
    bins P4_para_P2_8 = (12'b010000001000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// Abre PORT2 => Fecha PORT2

    // Interação do quarto pavimento para o primeiro
    bins P4_para_P1_1 = (12'b000100000000 => 12'b000101000000) iff(chamadas_mod_ref[0]); 	// S4 => Ativa motor
    bins P4_para_P1_2 = (12'b000101000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// Ativa motor => Estado transição
    bins P4_para_P1_3 = (12'b000001000000 => 12'b001001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S3
    bins P4_para_P1_4 = (12'b001001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// S3 => Estado transição
    bins P4_para_P1_5 = (12'b000001000000 => 12'b010001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S2
  	bins P4_para_P1_6 = (12'b010001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// S2 => Estado transição
    bins P4_para_P1_7 = (12'b000001000000 => 12'b100001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S1
  	bins P4_para_P1_8 = (12'b100001000000 => 12'b100000000000) iff(chamadas_mod_ref[0]); 	// S1 => Desativa motor
    bins P4_para_P1_9 = (12'b100000000000 => 12'b100000010000) iff(chamadas_mod_ref[0]); 	// Desativa motor => Abre PORT1
    bins P4_para_P1_10 = (12'b100000010000 => 12'b100000000000) iff(chamadas_mod_ref[0]); // Abre PORT1 => Fecha PORT1

    // Interação do quarto pavimento para o quinto
    bins P4_para_P5_1 = (12'b000100000000 => 12'b000100100000) iff(chamadas_mod_ref[1]); 	// S4 => Ativa motor
    bins P4_para_P5_2 = (12'b000100100000 => 12'b000000100000) iff(chamadas_mod_ref[4]); 	// Ativa motor => Estado transição
    bins P4_para_P5_3 = (12'b000000100000 => 12'b000010100000) iff(chamadas_mod_ref[4]); 	// Estado transição => S5
  	bins P4_para_P5_4 = (12'b000010100000 => 12'b000010000000) iff(chamadas_mod_ref[4]); 	// S5 => Desativa motor
    bins P4_para_P5_5 = (12'b000010000000 => 12'b000010000001) iff(chamadas_mod_ref[4]); 	// Desativa motor => Abre PORT5
    bins P4_para_P5_6 = (12'b000010000001 => 12'b000010000000) iff(chamadas_mod_ref[4]); 	// Abre PORT5 => Fecha PORT5
}
  endgroup

//Covergroup para o 5 pavimento
covergroup CG_pavimento5 @(sequencia_atendimento);
coverpoint sequencia_atendimento{
  
    // Interação do quinto pavimento para o quinto
  	bins P5_para_P5_1= (12'b000010000000 => 12'b000010000001) iff(chamadas_mod_ref[4]); 	// S5 => Abre PORT4
  	bins P5_para_P5_2= (12'b000010000001 => 12'b000010000000) iff(chamadas_mod_ref[4]); 	// Abre PORT5 => Fecha PORT5

    // Interação do quinto pavimento para o quarto
  	bins P5_para_P4_1 = (12'b000010000000 => 12'b000011000000) iff(chamadas_mod_ref[3]); 	// S5 => Ativa motor
    bins P5_para_P4_2 = (12'b000011000000 => 12'b000001000000) iff(chamadas_mod_ref[3]); 	// Ativa motor => Estado transição
    bins P5_para_P4_3 = (12'b000001000000 => 12'b000101000000) iff(chamadas_mod_ref[3]); 	// Estado transição => S4
  	bins P5_para_P4_4 = (12'b000101000000 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// S4 => Desativa motor
    bins P5_para_P4_5 = (12'b000100000000 => 12'b000100000010) iff(chamadas_mod_ref[3]); 	// Desativa motor => Abre PORT4
    bins P5_para_P4_6 = (12'b000100000010 => 12'b000100000000) iff(chamadas_mod_ref[3]); 	// Abre PORT4 => Fecha PORT4

    // Interação do quinto pavimento para o terceiro
  	bins P5_para_P3_1 = (12'b000010000000 => 12'b000011000000) iff(chamadas_mod_ref[2]); 	// S5 => Ativa motor
    bins P5_para_P3_2 = (12'b000011000000 => 12'b000001000000) iff(chamadas_mod_ref[2]); 	// Ativa motor => Estado transição
    bins P5_para_P3_3 = (12'b000001000000 => 12'b000101000000) iff(chamadas_mod_ref[2]); 	// Estado transição => S4
  	bins P5_para_P3_4 = (12'b000101000000 => 12'b000001000000) iff(chamadas_mod_ref[2]); 	// S4 => Estado transição
    bins P5_para_P3_5 = (12'b000001000000 => 12'b001001000000) iff(chamadas_mod_ref[2]); 	// Estado transição => S3
  	bins P5_para_P3_6 = (12'b001001000000 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// S3 => Desativa motor
    bins P5_para_P3_7 = (12'b001000000000 => 12'b001000000100) iff(chamadas_mod_ref[2]); 	// Desativa motor => Abre PORT3
    bins P5_para_P3_8 = (12'b001000000100 => 12'b001000000000) iff(chamadas_mod_ref[2]); 	// Abre PORT3 => Fecha PORT3

    // Interação do quinto pavimento para o segundo
    bins P5_para_P2_1 = (12'b000010000000 => 12'b000011000000) iff(chamadas_mod_ref[1]); 	// S5 => Ativa motor
    bins P5_para_P2_2 = (12'b000011000000 => 12'b000001000000) iff(chamadas_mod_ref[1]); 	// Ativa motor => Estado transição
    bins P5_para_P2_3 = (12'b000001000000 => 12'b000101000000) iff(chamadas_mod_ref[1]); 	// Estado transição => S4
    bins P5_para_P2_4 = (12'b000101000000 => 12'b000001000000) iff(chamadas_mod_ref[1]); 	// S4 => Estado transição
    bins P5_para_P2_5 = (12'b000001000000 => 12'b001001000000) iff(chamadas_mod_ref[1]); 	// Estado transição => S3
  	bins P5_para_P2_6 = (12'b001001000000 => 12'b000001000000) iff(chamadas_mod_ref[1]); 	// S3 => Estado transição
    bins P5_para_P2_7 = (12'b000001000000 => 12'b010001000000) iff(chamadas_mod_ref[1]); 	// Estado transição => S2
  	bins P5_para_P2_8 = (12'b010001000000 => 12'b010000000000) iff(chamadas_mod_ref[1]); 	// S2 => Desativa motor
    bins P5_para_P2_9 = (12'b010000000000 => 12'b010000001000) iff(chamadas_mod_ref[1]); 	// Desativa motor => Abre PORT2
    bins P5_para_P2_10 = (12'b010000001000 => 12'b010000000000) iff(chamadas_mod_ref[1]); // Abre PORT2 => Fecha PORT2

    // Interação do quinto pavimento para o primeiro
    bins P5_para_P1_1 = (12'b000010000000 => 12'b000011000000) iff(chamadas_mod_ref[0]); 	// S5 => Ativa motor
    bins P5_para_P1_2 = (12'b000011000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// Ativa motor => Estado transição
    bins P5_para_P1_3 = (12'b000001000000 => 12'b000101000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S4
    bins P5_para_P1_4 = (12'b000101000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// S4 => Estado transição
    bins P5_para_P1_5 = (12'b000001000000 => 12'b001001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S3
    bins P5_para_P1_6 = (12'b001001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// S3 => Estado transição
    bins P5_para_P1_7 = (12'b000001000000 => 12'b010001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S2
    bins P5_para_P1_8 = (12'b010001000000 => 12'b000001000000) iff(chamadas_mod_ref[0]); 	// S2 => Estado transição
    bins P5_para_P1_9 = (12'b000001000000 => 12'b100001000000) iff(chamadas_mod_ref[0]); 	// Estado transição => S1
  	bins P5_para_P1_10 = (12'b100001000000 => 12'b100000000000) iff(chamadas_mod_ref[0]); // S1 => Desativa motor
    bins P5_para_P1_11 = (12'b100000000000 => 12'b100000010000) iff(chamadas_mod_ref[0]); // Desativa motor => Abre PORT1
    bins P5_para_P1_12 = (12'b100000010000 => 12'b100000000000) iff(chamadas_mod_ref[0]); // Abre PORT1 => Fecha PORT1
}
  endgroup

  // Instanciando os coverpoints;  
  
CG_pavimento1 cg_teste1_inst = new;
CG_pavimento2 cg_teste2_inst = new;
CG_pavimento3 cg_teste3_inst = new;
CG_pavimento4 cg_teste4_inst = new;
CG_pavimento5 cg_teste5_inst = new;
  
  /**************************************************************************************/


// Clock de períoo igual a 2 ns
initial begin
CLOCK = 0;
forever #1 CLOCK = ~CLOCK;
end 

initial begin
$dumpfile("tb.vcd");
$dumpvars(1, tb_controle);
gerar_clock_random = 1;
count_clock = 0;
andar = 0;
tempo_requisicao = 0;
chamada_interna_externa = 0;
count_porta = 0;
count_verificar_portas = 0;
  
RESET = 1;
#20
RESET = 0; // Liberação do reset após 20 unidades de tempo

  while(cg_teste1_inst.get_coverage() < 100 || cg_teste2_inst.get_coverage() < 100 || cg_teste3_inst.get_coverage() < 100 || cg_teste4_inst.get_coverage() < 100 || cg_teste5_inst.get_coverage() < 100) begin
    #100000;
  end

$finish; // Finaliza a simulação após todos os testes

end
  
  
always @(posedge CLOCK) begin
    // Gera um novo tempo de requisição, se necessário
    if (gerar_clock_random) begin
      tempo_requisicao = $urandom_range(600,1);
      andar = $urandom_range(1, 5); // Gera um novo andar
      chamada_interna_externa = $urandom_range(0,1);
      gerar_clock_random = 0;
    end

    // Incrementa o contador
    count_clock = count_clock + 1;

    // Verifica se o contador atingiu o tempo de requisição
    if (count_clock == tempo_requisicao) begin 
		count_clock = 0;
      if (chamada_interna_externa) begin 
        // Liga o andar correspondente
        case(andar)
          1: begin
            botoes_externos[0] = 1;
            gerar_clock_random = 1;
          end
          2: begin
           botoes_externos[1] = 1;
        	gerar_clock_random = 1;            
          end
          3: begin
            botoes_externos[2] = 1;
        	gerar_clock_random = 1;            
          end
          4: begin
            botoes_externos[3] = 1;
            gerar_clock_random = 1;
          end
          5: begin
            botoes_externos[4] = 1;
            gerar_clock_random = 1;
          end                  
        endcase
      end else begin
        case(andar)
          1: begin
            botoes_internos[0] = 1;
            gerar_clock_random = 1;
          end
          2: begin
            botoes_internos[1] = 1;
        	gerar_clock_random = 1;            
          end
          3: begin
            botoes_internos[2] = 1;
        	gerar_clock_random = 1;            
          end
          4: begin
            botoes_internos[3] = 1;
            gerar_clock_random = 1;
          end
          5: begin
            botoes_internos[4] = 1;
            gerar_clock_random = 1;
          end                  
        endcase        
        end
    end else begin
        // Reseta os sinais de saída para evitar ativações contínuas
        botoes_externos = 5'b00000;
      	botoes_internos = 5'b00000;
    end
end

  
// Always que armazena as chamadas para botões internos e externos do elevador
always @(pavimentos_mod_ref, RESET, chamadas_mod_ref) begin
  integer i; 
  if (RESET) begin
    for (i = 5; i > 0; i = i - 1) begin
      chamadas_mod_ref[i] <= 0;
    end
  end else begin
    for (i = 0; i < 5; i = i + 1) begin
      if (pavimentos_mod_ref[i] && chamadas_mod_ref[i]) begin
        while (pavimentos_mod_ref[i] && chamadas_mod_ref[i]) begin
          if (portas_mod_ref[i]) begin
            @(negedge portas_mod_ref[i]);
            #2
            chamadas_mod_ref[i] = 0; 
          end else if (!pavimentos_mod_ref[i]) begin
            break;
          end else begin
            @(portas_mod_ref[i] or pavimentos_mod_ref);
          end
        end
      end
    end
  end
end


// Comportamento do Mod Ref Igual ao Elevador Testado

// Always que armazena as chamadas dos botões externos e internos
always @(botoes_externos or botoes_internos or RESET) begin
  if (RESET) begin
    chamadas_mod_ref = 5'b00000;
  end else begin
    chamadas_mod_ref |= botoes_internos;
    chamadas_mod_ref |= botoes_externos;
  end
end
  
// Verifica se as chamadas do elevador está batendo com as do modelo de referencia

always @(pavimentos_elev) begin
  atendimento_lista.push_back(pavimentos_elev);
end

always @(pavimentos_mod_ref) begin
  atendimento_mod_ref_lista.push_back(pavimentos_mod_ref);
end

always @(posedge CLOCK) begin
  if(!atendimento_lista.empty() && !atendimento_mod_ref_lista.empty()) begin
    if (atendimento_lista[0] !== atendimento_mod_ref_lista[0]) begin
      //$display("Erro: O comportamento do elevador está diferente do modelo de referência!!!\n%b\n%b", atendimento_lista[0], atendimento_mod_ref_lista[0]);
    end else begin
      //$display($time, "Correto: O comportamento do elevador está coerente com o do modelo de referência.\n%b\n%b", atendimento_lista[0], atendimento_mod_ref_lista[0]);   
    end
    atendimento_lista.pop_front();
    atendimento_mod_ref_lista.pop_front();
  end
end

// Verifica se o motor do elevador está igual ao do modelo de referência 

always @(SAIDA_CONV) begin
  motor_lista.push_back(SAIDA_CONV);
end

always @(SAIDA_CONV_MOD_REF) begin
  motor_ref_lista.push_back(SAIDA_CONV_MOD_REF);
end

always @(posedge CLOCK) begin
  if(!motor_lista.empty() && !motor_ref_lista.empty()) begin
    if (motor_lista[0] !== motor_ref_lista[0]) begin
      //$display("Erro: O motor do elevador está com o estado diferente do modelo de referência!!!");
    end else begin
      //$display($time, "Correto: O motor do elevador está com o estado igual ao do modelo de referência.\n%b\n%b", motor_lista[0], motor_ref_lista[0]);   
    end
    motor_lista.pop_front();
    motor_ref_lista.pop_front();
  end
end

// Verifica se a porta do elevador abre e fecha igual a do modelo de referência
always @(portas_elev) begin
  porta_lista.push_back(portas_elev);
end

always @(portas_mod_ref) begin
  porta_mod_ref_lista.push_back(portas_mod_ref);
end

always @(posedge CLOCK) begin
  if(!porta_lista.empty() && !porta_mod_ref_lista.empty()) begin
    if (porta_lista[0] !== porta_mod_ref_lista[0]) begin
      //$display("Erro: O comportamento das Portas está diferente do modelo de refêrencia!!!\n%b\n%b",porta_lista[0], porta_mod_ref_lista[0]);
    end else begin
      //$display($time, "Correto: O comportamento das Portas está igual ao modelo de referência.\n%b\n%b", porta_lista[0], porta_mod_ref_lista[0]);   
    end
    porta_lista.pop_front();
    porta_mod_ref_lista.pop_front();
  end
end
  
  
// Verificar se a porta fica 50 unidades de tempo aberta.
  
always @(posedge portas_mod_ref[0]) begin
  count_porta = 0;  // Inicializa o contador
  while (count_porta < 50) begin
    @(posedge CLOCK);
    count_porta++;
  end

  // Verificação após 50 ciclos de clock
  if (count_porta != 50) begin
    //$display("Erro: a porta 1 não ficou 50 unidades de tempo aberta!!!\n%d", count_porta);
  end else begin
    //$display("Correto: a porta 1 ficou 50 unidades de tempo aberta.\n%d", count_porta);
  end
end

  always @(posedge portas_elev[1]) begin
  count_porta = 0;  // Inicializa o contador
  while (count_porta < 50) begin
    @(posedge CLOCK);
    count_porta++;
  end

  // Verificação após 50 ciclos de clock
  if (count_porta != 50) begin
    //$display("Erro: a porta 2 não ficou 50 unidades de tempo aberta!!!\n%d", count_porta);
  end else begin
    //$display("Correto: a porta 2 ficou 50 unidades de tempo aberta.\n%d", count_porta);
  end
end

  always @(posedge portas_elev[2]) begin
  count_porta = 0;  // Inicializa o contador
  while (count_porta < 50) begin
    @(posedge CLOCK);
    count_porta++;
  end

  // Verificação após 50 ciclos de clock
  if (count_porta != 50) begin
    //$display("Erro: a porta 3 não ficou 50 unidades de tempo aberta!!!\n%d", count_porta);
  end else begin
    //$display("Correto: a porta 3 ficou 50 unidades de tempo aberta.\n%d", count_porta);
  end
end

  always @(posedge portas_elev[3]) begin
  count_porta = 0;  // Inicializa o contador
  while (count_porta < 50) begin
    @(posedge CLOCK);
    count_porta++;
  end

  // Verificação após 50 ciclos de clock
  if (count_porta != 50) begin
    //$display("Erro: a porta 4 não ficou 50 unidades de tempo aberta!!!\n%d", count_porta);
  end else begin
    //$display("Correto: a porta 4 ficou 50 unidades de tempo aberta.\n%d", count_porta);
  end
end

  always @(posedge portas_elev[4]) begin
  count_porta = 0;  // Inicializa o contador
  while (count_porta < 50) begin
    @(posedge CLOCK);
    count_porta++;
  end

  // Verificação após 50 ciclos de clock
  if (count_porta != 50) begin
    //$display("Erro: a porta 5 não ficou 50 unidades de tempo aberta!!!\n%d", count_porta);
  end else begin
    //$display("Correto: a porta 5 ficou 50 unidades de tempo aberta.\n%d", count_porta);
  end
end

// Verificar se tem mais de uma porta aberta
  
  
  always @(portas_elev) begin
    count_verificar_portas = 0;     // Inicializa a contagem

    // Conta os bits '1' na variável por
  for (int i = 0; i < $bits(portas_elev); i = i + 1) begin
        if (portas_elev[i]) begin
            count_verificar_portas = count_verificar_portas + 1;
        end
    end

    // Verifica se há mais de um bit ativo
  if (count_verificar_portas > 1) begin
      $display("Erro: Tem mais de uma porta aberta ao mesmo no elevador!!!\nLista das Portas: %b", portas_elev);
    end else begin
      //$display("Correto: Não tem mais de uma porta aberta ao mesmo tempo.\nLista das Portas: %b", portas_elev);
    end
end


  
// Verificar se alguma porta abriu enquanto o motor estava ligado
  
  always @(portas_elev) begin
    if (portas_elev != 0 && SAIDA_CONV != 0) begin
      $display("Erro: Porta abriu enquanto o elevador estava em movimento!!!\nLista das Portas: %b\nMotor:%d", portas_elev, SAIDA_CONV);
    end else begin
      //$display("Correto: Todas as portas fechadas enquanto o elevador se movimenta: %b\nMotor:%d", portas_elev, SAIDA_CONV);
    end
  end  

// Dois sensores ligados ao mesmo tempo
  
  
always @(posedge CLOCK) begin
    count_para_sensores = 0;     // Inicializa a contagem

    // Conta os bits '1' na variável pavimento_atual
    for (int i = 0; i < $bits(pavimentos_elev); i = i + 1) begin
        if (pavimentos_elev[i]) begin
            count_para_sensores = count_para_sensores + 1;
        end
    end

    // Verifica se há mais de um bit ativo
    if (count_para_sensores > 1) begin
        #2
        if (SAIDA_CONV == 0) begin
          $display("Correto: O elevador parou devido ao mau funcionamento dos sensores.");
        end else begin
          $display("Erro: O elevador não parou com o mau funcionamento dos sensores!!!");
        end
    end
end

always @(sequencia_atendimento) begin
  //$display("Coverage A1: %d", cg_teste1_inst.get_coverage());
  //$display("Coverage A2:  %d", cg_teste2_inst.get_coverage());
  //$display("Coverage A3:  %d", cg_teste3_inst.get_coverage());
  //$display("Coverage A4:  %d", cg_teste4_inst.get_coverage());
  //$display("Coverage A5:  %d", cg_teste5_inst.get_coverage());
end

endmodule
