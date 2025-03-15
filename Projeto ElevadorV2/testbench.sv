`include "sequenciador.sv"
`include "transicao_portas.sv"
`include "duv01.sv"
`include "duv02.sv"
`include "duv03.sv"
//`include "duv04.sv" - Não funciona
`include "duv05.sv"
`include "duv06.sv"
`include "duv07.sv"
`include "duv08.sv"
`include "duv09.sv"

module tb_controle;

  // Definindo os sinais como reg e wire
  logic RESET, reset_inicio, CLOCK;                                           // Sinais de reset e clock
  // Botões
  logic BI1, BI2, BI3, BI4, BI5;                                // Botões internos para cada andar
  logic BE1UP, BE2UP, BE3UP, BE4UP;                             // Botões externos de subida
  logic BE5DOWN, BE2DOWN, BE3DOWN, BE4DOWN;                     // Botões externos de descida

  // Elevadores
  logic SPA1, SPA2, SPA3, SPA4, SPA5, SPAI;                      // Sensores de porta aberta
  logic SPF1, SPF2, SPF3, SPF4, SPF5, SPFI;                      // Sensores de porta fechada
  logic SA1, SA2, SA3, SA4, SA5;                                 // Sensores de andar
  logic OPENDOOR, CLOSEDOOR;                                    // Sinais para abrir e fechar a porta
  logic NON_STOP;                                               // Sinal de modo non-stop
  logic POTENCIA;                                               // Sinal de potência
  wire [1:0] MOTOR;                                             // Estado do motor
  wire [1:0] PORT1, PORT2, PORT3, PORT4, PORT5, PORT_INTERNA;   // Estado dos motores das portas
  wire ALERTA;                                                  // Sinal de alerta
  wire [3:0] DISPLAY;                                           // Display de andar

  // Modelo de Referência
  logic SPA1_MOD_REF, SPA2_MOD_REF, SPA3_MOD_REF, SPA4_MOD_REF, SPA5_MOD_REF, SPAI_MOD_REF;                      // Sensores de porta aberta
  logic SPF1_MOD_REF, SPF2_MOD_REF, SPF3_MOD_REF, SPF4_MOD_REF, SPF5_MOD_REF, SPFI_MOD_REF;                      // Sensores de porta fechada
  logic SA1_MOD_REF, SA2_MOD_REF, SA3_MOD_REF, SA4_MOD_REF, SA5_MOD_REF;                                 // Sensores de andar
  logic OPENDOOR_MOD_REF, CLOSEDOOR_MOD_REF;                                    // Sinais para abrir e fechar a porta
  logic NON_STOP_MOD_REF;                                               // Sinal de modo non-stop
  logic POTENCIA_MOD_REF;                                               // Sinal de potência
  wire [1:0] MOTOR_MOD_REF;                                             // Estado do motor
  wire [1:0] PORT1_MOD_REF, PORT2_MOD_REF, PORT3_MOD_REF, PORT4_MOD_REF, PORT5_MOD_REF, PORT_INTERNA_MOD_REF;   // Estado dos motores das portas
  wire ALERTA_MOD_REF;                                                  // Sinal de alerta
  wire [3:0] DISPLAY_MOD_REF;                                           // Display de andar



  /***************************** Criação de variáveis e atribuições *****************************/

  int tempo_requiscao;                                          // Tempo de requisição                                     // Geração de clock aleatório                                            // Andar aleatório
  int chamada_interna_externa;                                  // Chamada interna ou externa
  int chamada_up_down;                                          // Chamada de subida ou descida
  int chamada_externa;                                          // Chamada externa
  int tempo_requisicao;                                         // Tempo de requisição
  int count_porta;                                              // Contador de porta

    // Variáveis para botões internos
  logic        gerar_clock_random_interna;
  int          tempo_requisicao_interna;
  int          count_clock_interna;        // Contador de clock
  int          andar_random;

  // Variáveis para botões externos
  logic        gerar_clock_random_externa;
  int          tempo_requisicao_externa;
  int          count_clock_externa;

  logic [4:0] motor_lista[$];
  logic [4:0] motor_ref_lista[$];

  logic [4:0] porta_lista[$];
  logic [4:0] porta_mod_ref_lista[$];  

  /***************************** Atribuições de Sensores do Mod Ref ******************************/

    // Pavimentos do elevador
  logic [4:0] pavimentos_elev_ref; 
  assign pavimentos_elev_ref[0] = SA1_MOD_REF;
  assign pavimentos_elev_ref[1] = SA2_MOD_REF;
  assign pavimentos_elev_ref[2] = SA3_MOD_REF;
  assign pavimentos_elev_ref[3] = SA4_MOD_REF;
  assign pavimentos_elev_ref[4] = SA5_MOD_REF;

    // Sensores de porta aberta
  logic [4:0] sensores_pa_ref; 
  assign sensores_pa_ref[0] = SPA1_MOD_REF;
  assign sensores_pa_ref[1] = SPA2_MOD_REF;
  assign sensores_pa_ref[2] = SPA3_MOD_REF;
  assign sensores_pa_ref[3] = SPA4_MOD_REF;
  assign sensores_pa_ref[4] = SPA5_MOD_REF;

    // Sensores de porta fechada
  logic [4:0] sensores_pf_ref; 
  assign sensores_pf_ref[0] = SPF1_MOD_REF;
  assign sensores_pf_ref[1] = SPF2_MOD_REF;
  assign sensores_pf_ref[2] = SPF3_MOD_REF;
  assign sensores_pf_ref[3] = SPF4_MOD_REF;
  assign sensores_pf_ref[4] = SPF5_MOD_REF;

  /**************************************** Atribuições de Portas ********************************************/
    logic [9:0] portas_mod_ref;
    assign portas_mod_ref[1:0] = PORT1_MOD_REF;
    assign portas_mod_ref[3:2] = PORT2_MOD_REF;
    assign portas_mod_ref[5:4] = PORT3_MOD_REF;
    assign portas_mod_ref[7:6] = PORT4_MOD_REF;
    assign portas_mod_ref[9:8] = PORT5_MOD_REF;

    logic [9:0] portas_elev;
    assign portas_elev[1:0] = PORT1;
    assign portas_elev[3:2] = PORT2;
    assign portas_elev[5:4] = PORT3;
    assign portas_elev[7:6] = PORT4;
    assign portas_elev[9:8] = PORT5;

  /***************************** Atribuições de Sensores ******************************/
  
  // Pavimentos do elevador
  logic [4:0] pavimentos_elev; 
  assign pavimentos_elev[0] = SA1;
  assign pavimentos_elev[1] = SA2;
  assign pavimentos_elev[2] = SA3;
  assign pavimentos_elev[3] = SA4;
  assign pavimentos_elev[4] = SA5;

  // Sensores de porta aberta
  logic [4:0] sensores_pa; 
  assign sensores_pa[0] = SPA1;
  assign sensores_pa[1] = SPA2;
  assign sensores_pa[2] = SPA3;
  assign sensores_pa[3] = SPA4;
  assign sensores_pa[4] = SPA5;

  // Sensores de porta fechada
  logic [4:0] sensores_pf; 
  assign sensores_pf[0] = SPF1;
  assign sensores_pf[1] = SPF2;
  assign sensores_pf[2] = SPF3;
  assign sensores_pf[3] = SPF4;
  assign sensores_pf[4] = SPF5;

  logic [4:0] chamadas_mod_ref;                                 // Armazena as chamadas ativas dos pavimentos
  logic [4:0] chamadas_subir_ref, chamadas_descer_ref;          // Armazena as chamadas de subida e descida

  logic [4:0] atendimento_lista[$];
  logic [4:0] atendimento_mod_ref_lista[$];

/*************************************** Instanciações ****************************************/

  mod_ref mod_ref (
    .reset(RESET), .clock(CLOCK), 
    .bi1(BI1), .bi2(BI2), .bi3(BI3), .bi4(BI4), .bi5(BI5),
    .be1UP(BE1UP), .be2UP(BE2UP), .be3UP(BE3UP), .be4UP(BE4UP),
    .be2Down(BE2DOWN), .be3Down(BE3DOWN), .be4Down(BE4DOWN),  
    .be5Down(BE5DOWN),
    .sPa1(SPA1_MOD_REF), .sPa2(SPA2_MOD_REF), .sPa3(SPA3_MOD_REF), .sPa4(SPA4_MOD_REF), .sPa5(SPA5_MOD_REF), .sPaI(SPAI_MOD_REF),
    .sPf1(SPF1_MOD_REF), .sPf2(SPF2_MOD_REF), .sPf3(SPF3_MOD_REF), .sPf4(SPF4_MOD_REF), .sPf5(SPF5_MOD_REF), .sPfI(SPFI_MOD_REF),
    .sA1(SA1_MOD_REF), .sA2(SA2_MOD_REF), .sA3(SA3_MOD_REF), .sA4(SA4_MOD_REF), .sA5(SA5_MOD_REF),
    .openDoor(OPENDOOR_MOD_REF), .closeDoor(CLOSEDOOR_MOD_REF),
    .non_stop(NON_STOP_MOD_REF),
    .potencia(POTENCIA_MOD_REF), 
    .motor(MOTOR_MOD_REF),
    .port1(PORT1_MOD_REF), .port2(PORT2_MOD_REF), .port3(PORT3_MOD_REF), .port4(PORT4_MOD_REF), .port5(PORT5_MOD_REF), .port_interna(PORT_INTERNA_MOD_REF),
    .alerta(ALERTA_MOD_REF),
    .display(DISPLAY_MOD_REF)
  );

  controle01 elev1 (
    .reset(RESET), .clock(CLOCK), 
    .bi1(BI1), .bi2(BI2), .bi3(BI3), .bi4(BI4), .bi5(BI5),
    .be1UP(BE1UP), .be2UP(BE2UP), .be3UP(BE3UP), .be4UP(BE4UP),
    .be2Down(BE2DOWN), .be3Down(BE3DOWN), .be4Down(BE4DOWN),  
    .be5Down(BE5DOWN),
    .sPa1(SPA1), .sPa2(SPA2), .sPa3(SPA3), .sPa4(SPA4), .sPa5(SPA5), .sPaI(SPAI),
    .sPf1(SPF1), .sPf2(SPF2), .sPf3(SPF3), .sPf4(SPF4), .sPf5(SPF5), .sPfI(SPFI),
    .sA1(SA1), .sA2(SA2), .sA3(SA3), .sA4(SA4), .sA5(SA5),
    .openDoor(OPENDOOR), .closeDoor(CLOSEDOOR),
    .non_stop(NON_STOP),
    .potencia(POTENCIA), 
    .motor(MOTOR),
    .port1(PORT1), .port2(PORT2), .port3(PORT3), .port4(PORT4), .port5(PORT5), .port_interna(PORT_INTERNA),
    .alerta(ALERTA),
    .display(DISPLAY)
  );

  /******************************************** Instanciações  ****************************************************/
   
  seq_pavimento my_seq_pavimento (
    .clk(CLOCK), 
    .rst(reset_inicio),
    .motor(MOTOR),
    .s1(SA1), 
    .s2(SA2), 
    .s3(SA3), 
    .s4(SA4), 
    .s5(SA5)
  );
  
  time_trans_port my_ttp1 (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT1),
    .spa(SPA1), 
    .spf(SPF1)
  );
  
  time_trans_port my_ttp2 (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT2),
    .spa(SPA2), 
    .spf(SPF2)
  );
  
  time_trans_port my_ttp3 (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT3),
    .spa(SPA3), 
    .spf(SPF3)
  );
  
  time_trans_port my_ttp4 (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT4),
    .spa(SPA4), 
    .spf(SPF4)
  );
  
  time_trans_port my_ttp5 (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT5),
    .spa(SPA5), 
    .spf(SPF5)
  );

  time_trans_port my_ttp_i (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT_INTERNA),
    .spa(SPAI), 
    .spf(SPFI)
  );

  /******************************************** Instanciações Mod Ref ****************************************************/

  seq_pavimento my_seq_pavimento_ref (
    .clk(CLOCK), 
    .rst(reset_inicio),
    .motor(MOTOR),
    .s1(SA1_MOD_REF), 
    .s2(SA2_MOD_REF), 
    .s3(SA3_MOD_REF), 
    .s4(SA4_MOD_REF), 
    .s5(SA5_MOD_REF)
  );
  
  time_trans_port my_ttp1_ref (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT1_MOD_REF),
    .spa(SPA1_MOD_REF), 
    .spf(SPF1_MOD_REF)
  );
  
  time_trans_port my_ttp2_ref (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT2_MOD_REF),
    .spa(SPA2_MOD_REF), 
    .spf(SPF2_MOD_REF)
  );
  
  time_trans_port my_ttp3_ref (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT3_MOD_REF),
    .spa(SPA3_MOD_REF), 
    .spf(SPF3_MOD_REF)
  );
  
  time_trans_port my_ttp4_ref (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT4_MOD_REF),
    .spa(SPA4_MOD_REF), 
    .spf(SPF4_MOD_REF)
  );
  
  time_trans_port my_ttp5_ref (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT5_MOD_REF),
    .spa(SPA5_MOD_REF), 
    .spf(SPF5_MOD_REF)
  );

  time_trans_port my_ttp_i_ref (
    .clk(CLOCK), 
    .rst(RESET),
    .motorPorta(PORT_INTERNA_MOD_REF),
    .spa(SPAI_MOD_REF), 
    .spf(SPFI_MOD_REF)
  );

/**************************************** Atribuições *****************************************/

    // Botões internos
  logic [4:0] botoes_internos; 
  assign BI1 = botoes_internos[0];
  assign BI2 = botoes_internos[1];
  assign BI3 = botoes_internos[2];
  assign BI4 = botoes_internos[3];
  assign BI5 = botoes_internos[4];

    // Botões externos de subida
  logic [3:0] botoes_externos_up; 
  assign BE1UP = botoes_externos_up[0];
  assign BE2UP = botoes_externos_up[1];
  assign BE3UP = botoes_externos_up[2];
  assign BE4UP = botoes_externos_up[3];

    // Botões externos de descida
  logic [3:0] botoes_externos_down; 
  assign BE2DOWN = botoes_externos_down[0];
  assign BE3DOWN = botoes_externos_down[1];
  assign BE4DOWN = botoes_externos_down[2];
  assign BE5DOWN = botoes_externos_down[3];

//===========================================================
// Covergroups
//===========================================================

//------- Chamadas Externas UP -------
covergroup convergroup_externo_up @(botoes_externos_up);
  // Coverpoint para botões externos (4 bits)
  coverpoint botoes_externos_up {
    // Bins para valores com exatamente um bit ativo
    bins chamadas_bins[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
    // Ignora valores que não possuam exatamente um bit ativo
    ignore_bins ignore_chamadas = {[4'b0000:4'b1111]} with ($countones(item) != 1);
  }

  // Coverpoint para referência de pavimentos (5 bits)
  coverpoint pavimentos_elev_ref {
    // Bins para valores com exatamente um bit ativo
    bins andares_bins[] = {5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000, 5'b00000};
    // Ignora valores com mais de um bit ativo
    ignore_bins ignore_andares = {[5'b00000:5'b11111]} with ($countones(item) > 1);
  }

  // Cross para combinar botoes_externos_up e pavimentos_elev_ref
  externas_up: cross botoes_externos_up, pavimentos_elev_ref;
endgroup


//------- Chamadas Externas DOWN -------
covergroup convergroup_externo_down @(botoes_externos_down);
  // Coverpoint para botões externos (4 bits)
  coverpoint botoes_externos_down {
    bins chamadas_bins[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
    ignore_bins ignore_chamadas = {[4'b0000:4'b1111]} with ($countones(item) != 1);
  }

  // Coverpoint para referência de pavimentos (5 bits)
  coverpoint pavimentos_elev_ref {
    bins andares_bins[] = {5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000, 5'b00000};
    ignore_bins ignore_andares = {[5'b00000:5'b11111]} with ($countones(item) > 1);
  }

  // Cross para combinar botoes_externos_down e pavimentos_elev_ref
  externas_down: cross botoes_externos_down, pavimentos_elev_ref;
endgroup


//------- Chamadas Internas -------
covergroup convergroup_interno @(botoes_internos);
  // Coverpoint para botões internos (5 bits)
  coverpoint botoes_internos {
    bins chamadas_bins[] = {5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000};
    ignore_bins ignore_chamadas = {[5'b00000:5'b11111]} with ($countones(item) != 1);
  }

  // Coverpoint para referência de pavimentos (5 bits)
  coverpoint pavimentos_elev_ref {
    bins andares_bins[] = {5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000, 5'b00000};
    ignore_bins ignore_andares = {[5'b00000:5'b11111]} with ($countones(item) > 1);
  }

  // Cross para combinar botoes_internos e pavimentos_elev_ref
  internas: cross botoes_internos, pavimentos_elev_ref;
endgroup


// Instanciação das covergroups
convergroup_externo_up convergroup_externas_up_instanciacao   = new;
convergroup_externo_down convergroup_externas_down_instanciacao = new;
convergroup_interno convergroup_internas_instanciacao = new;


  /*
   tempo de duração do click do botão = 2ns
   tempo de porta totalmente aberta = 50 pclock -> 100ns 
   tempo de transição de porta aberta para fechada = 20 pclock -> 40ns 
   tempo de transição de porta fechada para aberta = 20 pclock -> 40ns 
   tempo de transição de andar = 20pclock -> 40ns
  */

  always #1 CLOCK = ~CLOCK; // Gera sinal de clock com período de 2 ns


initial begin

    $dumpfile("tb.vcd");
  $dumpvars(1,tb_controle);

    // Inicializando os sinais
    andar_random = 0;
    tempo_requiscao = 0;
    chamada_interna_externa = 0;
    chamada_up_down = 0;
    botoes_externos_up = 0;
    botoes_externos_down = 0;
    count_porta = 0;
    gerar_clock_random_interna = 1;
    gerar_clock_random_externa = 1;
    count_clock_interna        = 0;
    count_clock_externa        = 0;
    botoes_internos            = 5'b00000;
    botoes_externos_up         = 4'b0000;
    botoes_externos_down       = 4'b0000;

    //clock e reset.
  	reset_inicio = 1;
    RESET = 1;
    CLOCK = 0;

    // Botões internos - todos desligados
    botoes_internos[0] = 0;
    botoes_internos[1] = 0;
    botoes_internos[2] = 0;
    botoes_internos[3] = 0;
    botoes_internos[4] = 0;

    // Botões externos para subir - todos desligados
    botoes_externos_up[0] = 0;
    botoes_externos_up[1] = 0;
    botoes_externos_up[2] = 0;
    botoes_externos_up[3] = 0;

    // Botões externos para descer - todos desligados
    botoes_externos_down[0] = 0;
    botoes_externos_down[1] = 0;
    botoes_externos_down[2] = 0;
    botoes_externos_down[3] = 0;

    // Botões para abertura e fechamento da porta
    OPENDOOR_MOD_REF = 0;
    CLOSEDOOR_MOD_REF = 0;

    // Função Non-Stop desativada
    NON_STOP = 0;
    NON_STOP_MOD_REF = 0;

    // Potência ativa
    POTENCIA = 1;
    POTENCIA_MOD_REF = 1;

    #14 RESET = 0; reset_inicio = 0; //INICIO DO SISTEMA

      // while(convergroup_externas_up_instanciacao.externas_up.get_coverage() < 95 || convergroup_externas_down_instanciacao.externas_down.get_coverage() < 95 || convergroup_internas_instanciacao.internas.get_coverage() < 95) begin
      //   $display("Cobertura das Chamadas Internas: %f, Cobertura das Chamadas Externas UP: %f, Cobertura das Chamadas Externas DOWN: %f", convergroup_internas_instanciacao.internas.get_coverage(), convergroup_externas_up_instanciacao.externas_up.get_coverage(), convergroup_externas_down_instanciacao.externas_down.get_coverage());
      //   #2000;
      // end
      #200000
  $finish();
end

/*************************************** Randomização *****************************************/

  // Processo para gerar chamadas internas
  always @(posedge CLOCK) begin
    if (gerar_clock_random_interna) begin
      tempo_requisicao_interna = $urandom_range(600, 1);
      andar_random            = $urandom_range(1, 5);  // Escolhe um andar de 1 a 5
      gerar_clock_random_interna = 0;
    end

    count_clock_interna = count_clock_interna + 1;
    
    if (count_clock_interna == tempo_requisicao_interna) begin
      count_clock_interna = 0;
      // Ativa o botão correspondente ao andar
      case (andar_random)
        1: botoes_internos[0] = 1;
        2: botoes_internos[1] = 1;
        3: botoes_internos[2] = 1;
        4: botoes_internos[3] = 1;
        5: botoes_internos[4] = 1;
      endcase
      gerar_clock_random_interna = 1;
    end else begin
      // Reseta os sinais quando não há requisição
      botoes_internos = 5'b00000;
    end
  end

  // Processo para gerar chamadas externas
  always @(posedge CLOCK) begin
    if (gerar_clock_random_externa) begin
      tempo_requisicao_externa = $urandom_range(600, 1);  // Você pode ajustar esse range conforme necessário
      chamada_externa         = $urandom_range(1, 4);     // Seleciona um botão externo de 1 a 4
      gerar_clock_random_externa = 0;
    end

    count_clock_externa = count_clock_externa + 1;

    if (count_clock_externa == tempo_requisicao_externa) begin
      count_clock_externa = 0;
      // Define se é chamada para subir ou descer
      chamada_up_down = $urandom_range(0, 1);
      
      if (chamada_up_down) begin
        case (chamada_externa)
          1: botoes_externos_up[0] = 1;
          2: botoes_externos_up[1] = 1;
          3: botoes_externos_up[2] = 1;
          4: botoes_externos_up[3] = 1;
        endcase
      end else begin
        case (chamada_externa)
          1: botoes_externos_down[0] = 1;
          2: botoes_externos_down[1] = 1;
          3: botoes_externos_down[2] = 1;
          4: botoes_externos_down[3] = 1;
        endcase
      end

      gerar_clock_random_externa = 1;
    end else begin
      // Reseta os sinais quando não há requisição
      botoes_externos_up   = 4'b0000;
      botoes_externos_down = 4'b0000;
    end
  end

/*************************************** Verificação *****************************************/

// Verifica se as chamadas do elevador está batendo com as do modelo de referencia

always @(pavimentos_elev) begin
    atendimento_lista.push_back(pavimentos_elev);
end

always @(pavimentos_elev_ref) begin
    atendimento_mod_ref_lista.push_back(pavimentos_elev_ref);
end

always @(posedge CLOCK) begin
  if(!atendimento_lista.empty() && !atendimento_mod_ref_lista.empty()) begin
      if (atendimento_lista[0] !== atendimento_mod_ref_lista[0]) begin
        //$display("Erro: O comportamento do elevador está diferente do modelo de referência!!!");
      end else begin
        //$display($time, "Correto: O comportamento do elevador está coerente com o do modelo de referência.\n%b\n%b", atendimento_lista[0], atendimento_mod_ref_lista[0]);   
      end
      atendimento_lista.pop_front();
      atendimento_mod_ref_lista.pop_front();
    end
end     

// Verifica se o motor do elevador está igual ao do modelo de referência 

always @(MOTOR) begin
    motor_lista.push_back(MOTOR);
end

always @(MOTOR_MOD_REF) begin
    motor_ref_lista.push_back(MOTOR_MOD_REF);
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

/************************************** Release 1 e 2 ****************************************/

always @(pavimentos_elev_ref, RESET, chamadas_mod_ref) begin
    integer i;      // Índice para iteração pelos andares
    if (RESET) begin
        // Durante o RESET, todas as chamadas são zeradas
        for (i = 0; i < 5; i = i + 1) begin
            chamadas_mod_ref[i] <= 0;
            chamadas_subir_ref[i]       <= 0;
            if (i > 0)
                chamadas_descer_ref[i-1] <= 0;
        end
        $display("[RESET] Todas as chamadas zeradas no tempo %0t", $time);
    end else begin
        // Para cada piso, verifica se há alguma chamada ativa
        for (i = 0; i < 5; i = i + 1) begin
            if ( (pavimentos_elev_ref[i] && chamadas_mod_ref[i]) || 
                 (pavimentos_elev_ref[i] && chamadas_subir_ref[i]) || 
                 ((i > 0) && pavimentos_elev_ref[i] && chamadas_descer_ref[i-1]) ) begin
                 
                // Uso de fork para tratar dois cenários simultâneos:
                // 1. Atendimento normal (abertura/fechamento da porta)
                // 2. Abortamento caso o elevador mude de andar antes da conclusão
                fork
                    begin : atendimento_normal
                        // Aguarda a abertura da porta (evento de descida)
                        @(negedge sensores_pf_ref[i]);
                        // Aguarda o fechamento da porta (evento de subida)
                        @(posedge sensores_pf_ref[i]);
                        // Após o ciclo de portas, reseta as chamadas do piso
                        chamadas_mod_ref[i] <= 0;
                        chamadas_subir_ref[i]       <= 0;
                        if (i > 0)
                            chamadas_descer_ref[i-1] <= 0;
                        $display("[OK] Atendimento concluído no piso %0d no tempo %0t", i, $time);
                    end
                    begin : atendimento_abortado
                        // Se houver mudança de andar antes de concluir o ciclo,
                        // o atendimento é abortado
                        @(pavimentos_elev_ref);
                        $display("[ABORT] Atendimento abortado no piso %0d por mudança de andar no tempo %0t", i, $time);
                    end
                join_any
                disable fork;
                
                // Verifica se todas as chamadas foram efetivamente resetadas.
                if ( (pavimentos_elev_ref[i] && chamadas_mod_ref[i]) ||
                     (pavimentos_elev_ref[i] && chamadas_subir_ref[i]) ||
                     ((i > 0) && pavimentos_elev_ref[i] && chamadas_descer_ref[i-1]) ) begin
                    $display("[ERRO] Falha ao resetar chamadas no piso %0d no tempo %0t", i, $time);
                end
            end
        end
    end
end
                  
/************************************** Release 3 e 4 ****************************************/
                            
//===================================================
// Alertas do Elevador
//===================================================

// Alerta para mais de um sensor de andar ativo
always @(pavimentos_elev) begin
  if (!ALERTA && ($countones(pavimentos_elev) > 1))
    $display("O elevador não acionou o alerta para múltiplos sensores de andar ativos! tempo = %0t", $time);
end

// Alertas relacionados aos motores das portas
always @(portas_elev, pavimentos_elev, MOTOR) begin
  // Alerta para mais de um motor de porta ativo
  if (!ALERTA && ($countones(portas_elev) > 1))
    $display("O elevador não acionou o alerta para múltiplos motores de porta ativos! tempo = %0t", $time);

  // Alerta para porta se movendo enquanto o motor de andar está ativo
  if (!ALERTA && ($countones(portas_elev) > 0) && (MOTOR != 0))
    $display("O elevador não emitiu alerta para a porta em movimento enquanto o motor do andar estava ativo! tempo = %0t", $time);

  // Alerta para porta externa se movendo em andar diferente do atual
  case (pavimentos_elev)
    5'b00001: begin
      if (|portas_elev[9:2])
        $display("O elevador não gerou alerta ao se mover com a porta externa em um andar diferente do atual! Andar = %b, Portas = %b, tempo = %0t", pavimentos_elev, portas_elev, $time);
    end
    5'b00010: begin
      if (|portas_elev[9:4] || |portas_elev[1:0])
        $display("O elevador não emitiu alerta ao se mover com a porta externa em um andar distinto do atual!Andar = %b, Portas = %b, tempo = %0t", pavimentos_elev, portas_elev, $time);
    end
    5'b00100: begin
      if (|portas_elev[9:6] || |portas_elev[3:0])
        $display("O elevador não acionou o alerta ao se mover com a porta externa em um andar diferente do atual! Andar = %b, Portas = %b, tempo = %0t", pavimentos_elev, portas_elev, $time);
    end
    5'b01000: begin
      if (|portas_elev[9:8] || |portas_elev[5:0])
        $display("O elevador não ativou o alerta quando a porta externa que estava diferente do andar atual quando o elevador estava se movendo! Andar = %b, Portas = %b, tempo = %0t", pavimentos_elev, portas_elev, $time);
    end
    5'b10000: begin
      if (|portas_elev[7:0])
        $display("O elevador não ativou o alerta quando a porta externa estava diferente do andar atual que estava se  movendo! Andar = %b, Portas = %b, tempo = %0t", pavimentos_elev, portas_elev, $time);
    end
  endcase
end

// Alerta para mais de um sensor de porta aberta ativo
always @(sensores_pa) begin
  if (!ALERTA && ($countones(sensores_pa) > 1))
    $display("O elevador não ativou o alarme para mais de um sensor de porta aberta ativo. tempo = %0t", $time);
end

// Alerta para mais de um sensor de porta fechada desativado
always @(sensores_pf) begin
  if (!ALERTA && ($countones(!sensores_pf) > 1))
    $display("O elevador não ativou o alarme para mais de um sensor de porta fechada desativado. tempo = %0t", $time);
end


endmodule;