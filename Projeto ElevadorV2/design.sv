module mod_ref(
	input logic reset, clock, 
    input logic bi1, bi2, bi3, bi4, bi5,
    input logic be1UP, be2UP, be3UP, be4UP,
    input logic be2Down, be3Down, be4Down, be5Down,
    input logic sPa1, sPa2, sPa3, sPa4, sPa5, sPaI,
    input logic sPf1, sPf2, sPf3, sPf4, sPf5, sPfI,
    input logic sA1, sA2, sA3, sA4, sA5,
    input logic openDoor, closeDoor,
    input logic non_stop,
    input logic potencia, 
    output logic [1:0] motor,
    output logic [1:0] port1, port2, port3, port4, port5, port_interna,
    output logic alerta,
  	output logic [3:0] display
);


    parameter Tempo_Porta = 50;         // Parâmetro geral do tempo de porta, 50 pulsos de clock.
    parameter Tempo_TransAndar = 20;    // Parâmetro geral do tempo de transição entre os andares
  	
    
    logic [4:0] requisicoes_andares;    // Vetor de requisições de andares
    logic [4:0] buffer_requisicoes;     // buffer para armazenar as requisicoes quando a potencia voltar
    logic [1:0] saida;                  // Variável que armamazena o valor do motor
    logic [1:0] ultimo_estado;
    int count_tempo_porta;              // Contador de tempo de porta
  	int i;                              // Variável de controle de laço
  	int andar_anterior;                 // Variável que armazena o andar anterior
    int count_port_abrindo;             // Contador de porta abrindo
    int count_port_fechando;            // Contador de porta fechando
    int reset_rotina;                   // Flag para indicar rotina do reset
    int potencia_rotina;                // Flag para indicar rotina da potencia
    int flag_potencia;
    int count_potencia;

/************************************ ATRIBUINDO VALORES **************************************/

   
    logic [4:0] sensores_portasA;       // Vetor de sensores de portas abertas  
    assign sensores_portasA[0] = sPa1;  
    assign sensores_portasA[1] = sPa2;
    assign sensores_portasA[2] = sPa3;
    assign sensores_portasA[3] = sPa4;
    assign sensores_portasA[4] = sPa5;

    logic [4:0] sensores_portasF;       // Vetor de sensores de portas fechadas
    assign sensores_portasF[0] = sPf1;
    assign sensores_portasF[1] = sPf2;
    assign sensores_portasF[2] = sPf3;
    assign sensores_portasF[3] = sPf4;
    assign sensores_portasF[4] = sPf5;

    logic [1:0] porta_fechada;          // Variável que armazena o estado da porta fechada

  	logic [11:0] lista_porta;           // Vetor de portas
  	assign port1 = lista_porta[1:0];    
    assign port2 = lista_porta[3:2];
    assign port3 = lista_porta[5:4];
    assign port4 = lista_porta[7:6];
    assign port5 = lista_porta[9:8];

    logic [4:0] pavimento_atual;        // Vetor de pavimentos
    assign pavimento_atual[0] = sA1;
    assign pavimento_atual[1] = sA2;
    assign pavimento_atual[2] = sA3;
    assign pavimento_atual[3] = sA4;
  	assign pavimento_atual[4] = sA5;
  	
    logic [4:0] chamadas_subida;
    logic [4:0] chamadas_descida;

    logic non_stopI;                    // Variável que armazena o estado de non_stop
    assign non_stopI = non_stop;        

    logic potenciaI;                    // Variável que armazena o estado de potencia
    assign potenciaI = potencia;

/**********************************************************************************************/

/***************************************** ENUM MOTOR *****************************************/
    
    // Enumeração do motor da porta
    typedef enum logic [1:0] {
        MOTOR_PARADO   = 2'b00,
        MOTOR_ABRINDO_PORTA  = 2'b01,
        MOTOR_FECHANDO_PORTA = 2'b10
    } motor_porta_t;


    // Variável para o estado atual do mortor da porta;
    motor_porta_t motor_porta;
    assign port_interna = motor_porta;

/**********************************************************************************************/

/************************************ MAQUINAS DE ESTADOS *************************************/
// Maquina Principal
    typedef enum logic [4:0] {
    ANDAR1 = 5'b00001, 
    ANDAR2 = 5'b00010,
    ANDAR3 = 5'b00100,
    ANDAR4 = 5'b01000,
    ANDAR5 = 5'b10000
    } maquina_principal_t;              // Enumeração dos andares

    maquina_principal_t andar_atual;    // Variável que armazena o andar atual
  	

    // Sub Maquina
    typedef enum logic [4:0] {
    ELEVADOR_PARADO,
    PORTA_ABRINDO,
    PORTA_ABERTA,
    PORTA_FECHANDO,
    PORTA_FECHADA
    } sub_maquina_t;                    // Enumeração dos estados da sub-maquina

    sub_maquina_t sub_maquina;          // Variável que armazena o estado da sub-maquina

/**********************************************************************************************/

/************************************* LÓGICA PRINCIPAL ***************************************/

    always @(posedge clock or posedge reset) begin 
      if (reset) begin
        lista_porta <= 0;
        requisicoes_andares <= 5'b00001;
        motor <= 2'b10;
        saida <= 2'b10;
        alerta <= 0;
        reset_rotina <= 1;
        potencia_rotina <= 0;
        flag_potencia <= 0;
        count_potencia <= 0;
      end else begin
            if (reset_rotina || potencia_rotina) begin
                if (reset_rotina) begin
                    if(andar_atual[0]) begin
                        sub_maquina <= ELEVADOR_PARADO;
                        motor_porta <= MOTOR_PARADO;
                        chamadas_descida <= 0;
                        chamadas_subida <= 0;
                        motor <= 0;
                        saida <= 0;
                        reset_rotina <= 0;
                    end 
                end else begin
                    if (andar_atual[0]) begin
                        motor <= 0;
                        saida <= 0;
                        requisicoes_andares <= buffer_requisicoes;
                    end
                end
            end else begin
                if (potencia) begin
                case (andar_atual)
//==============================================================
// ANDAR_1 - Lógica para o 1º Andar
//==============================================================
              	ANDAR1: begin
                    // Se a porta deve ser aberta ou existe uma requisição para o 1º andar
                    if (openDoor || requisicoes_andares[0]) begin
                        // Garante que o motor do elevador esteja parado enquanto a porta opera
                        motor <= 0;                      
                        // Verifica se o motor está realmente desligado (saída confirmada)
                        if (!motor) begin
                            // Máquina de estados interna para o controle da porta
                            case (sub_maquina)
                                //--------------------------------------------------------------------------
                                // Estado: ELEVADOR_PARADO
                                // Verifica se o sensor da porta fechada está inativo (indicando que a
                                // porta pode começar a abrir). Caso contrário, sinaliza alerta.
                                //--------------------------------------------------------------------------
                                ELEVADOR_PARADO: begin
                                    if (sensores_portasF[0]) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        alerta <= 1;
                                        // Permanece no mesmo estado se houver inconsistência
                                        sub_maquina <= sub_maquina;
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABRINDO
                                // Verifica se os sensores indicam que a porta está em movimento (ambos
                                // sensores de porta aberta e fechada inativos). Enquanto isso, aciona o
                                // motor da porta para o movimento de abertura.
                                //--------------------------------------------------------------------------
                                PORTA_ABRINDO: begin
                                  	lista_porta[0] <= 2'b01;
                                  	motor_porta <= MOTOR_ABRINDO_PORTA;
                                  	sub_maquina <= PORTA_ABERTA;
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABERTA
                                // A porta está aberta. Se houver nova requisição (botão openDoor), o
                                // contador de tempo é reiniciado. Se o tempo exceder o limite (Tempo_Porta)
                                // ou se o botão closeDoor for pressionado, inicia o fechamento da porta.
                                // Caso contrário, mantém a porta parada.
                                //--------------------------------------------------------------------------
                                PORTA_ABERTA: begin
                                    if (openDoor) begin
                                        count_tempo_porta <= 0;  // Reinicia o contador para manter a porta aberta
                                    end else begin
                                      if(sensores_portasA[0]) begin
                                        if (count_tempo_porta > Tempo_Porta || closeDoor) begin
                                            sub_maquina <= PORTA_FECHANDO;
                                            count_tempo_porta <= 0;  // Reinicia o contador para o ciclo de fechamento
                                        end else begin
                                            motor_porta <= MOTOR_PARADO;
                                          	lista_porta[1:0] <= 2'b00;
                                            count_tempo_porta++;
                                        end
                                      end
                                    end
                                end
                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHANDO
                                // Inicia o fechamento da porta. Se, durante o fechamento, o botão openDoor for
                                // pressionado, reverte a ação voltando para abertura. Enquanto a porta estiver
                                // em movimento de fechamento, aciona o motor correspondente. Quando o sensor
                                // indicar porta fechada, muda para o estado PORTA_FECHADA.
                                //--------------------------------------------------------------------------
                                PORTA_FECHANDO: begin
                                  	lista_porta[1:0] <= 2'b10;
                                  	motor_porta <= MOTOR_FECHANDO_PORTA;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        if (sPfI) begin
                                            sub_maquina <= PORTA_FECHADA;
                                        end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHADA
                                // A porta está completamente fechada. Garante que o motor da porta esteja
                                // parado. Se o botão openDoor for pressionado, reinicia o processo de abertura.
                                // Caso contrário, a requisição para o andar 1 é atendida e a máquina retorna ao
                                // estado ELEVADOR_PARADO.
                                //--------------------------------------------------------------------------
                                PORTA_FECHADA: begin
                                    lista_porta[1:0] <= MOTOR_PARADO;
                                    motor_porta <= MOTOR_PARADO;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        // Após fechar, confirma o atendimento da requisição e retorna ao estado parado
                                        if (!openDoor) begin
                                            requisicoes_andares[0] <= 0;
                                            sub_maquina <= ELEVADOR_PARADO;
                                        end
                                    end
                                end
                            endcase
                        end  
                    end else begin
                        //--------------------------------------------------------------------------
                        // Controle do motor do elevador para movimentação entre andares
                        //--------------------------------------------------------------------------
                        case (motor)
                            // Estado: 2'b00
                            // Se houver requisição para qualquer andar (do 2 ao 5), inicia o movimento do motor.
                            // Caso contrário, mantém o motor desligado.
                            2'b00: begin
                                if (|requisicoes_andares[4:1]) begin
                                    motor <= 2'b01;   // Liga o motor para iniciar o deslocamento
                                    saida <= 2'b01;   // Sinaliza que o motor está ativo
                                end else begin
                                    motor <= 2'b00;   // Mantém o motor parado
                                    saida <= 2'b00;   // Sinaliza que o motor está inativo
                                end
                            end
                        endcase
                    end
                end
//==============================================================
// ANDAR_2 - Lógica para o 2º Andar
//==============================================================
                ANDAR2: begin
                    // Se a porta deve ser aberta ou existe uma requisição para o 1º andar
                    if (openDoor || requisicoes_andares[1]) begin
                        // Garante que o motor do elevador esteja parado enquanto a porta opera
                        motor <= 0;                      
                        // Verifica se o motor está realmente desligado (saída confirmada)
                        if (!motor) begin
                            // Máquina de estados interna para o controle da porta
                            case (sub_maquina)
                                //--------------------------------------------------------------------------
                                // Estado: ELEVADOR_PARADO
                                // Verifica se o sensor da porta fechada está inativo (indicando que a
                                // porta pode começar a abrir). Caso contrário, sinaliza alerta.
                                //--------------------------------------------------------------------------
                                ELEVADOR_PARADO: begin
                                    if (sensores_portasF[1]) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        alerta <= 1;
                                        // Permanece no mesmo estado se houver inconsistência
                                        sub_maquina <= sub_maquina;
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABRINDO
                                // Verifica se os sensores indicam que a porta está em movimento (ambos
                                // sensores de porta aberta e fechada inativos). Enquanto isso, aciona o
                                // motor da porta para o movimento de abertura.
                                //--------------------------------------------------------------------------
                                PORTA_ABRINDO: begin
                                  	lista_porta[3:2] <= 2'b01;
                                  	motor_porta <= MOTOR_ABRINDO_PORTA;
                                  	sub_maquina <= PORTA_ABERTA;
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABERTA
                                // A porta está aberta. Se houver nova requisição (botão openDoor), o
                                // contador de tempo é reiniciado. Se o tempo exceder o limite (Tempo_Porta)
                                // ou se o botão closeDoor for pressionado, inicia o fechamento da porta.
                                // Caso contrário, mantém a porta parada.
                                //--------------------------------------------------------------------------
                                PORTA_ABERTA: begin
                                    if (openDoor) begin
                                        count_tempo_porta <= 0;  // Reinicia o contador para manter a porta aberta
                                    end else begin
                                      if(sensores_portasA[1]) begin
                                        if (count_tempo_porta > Tempo_Porta || closeDoor) begin
                                            sub_maquina <= PORTA_FECHANDO;
                                            count_tempo_porta <= 0;  // Reinicia o contador para o ciclo de fechamento
                                        end else begin
                                            motor_porta <= MOTOR_PARADO;
                                          	lista_porta[3:2] <= 2'b00;
                                            count_tempo_porta++;
                                        end
                                      end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHANDO
                                // Inicia o fechamento da porta. Se, durante o fechamento, o botão openDoor for
                                // pressionado, reverte a ação voltando para abertura. Enquanto a porta estiver
                                // em movimento de fechamento, aciona o motor correspondente. Quando o sensor
                                // indicar porta fechada, muda para o estado PORTA_FECHADA.
                                //--------------------------------------------------------------------------
                                PORTA_FECHANDO: begin
                                  	lista_porta[3:2] <= 2'b10;
                                  	motor_porta <= MOTOR_FECHANDO_PORTA;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        if (sPfI) begin
                                            sub_maquina <= PORTA_FECHADA;
                                        end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHADA
                                // A porta está completamente fechada. Garante que o motor da porta esteja
                                // parado. Se o botão openDoor for pressionado, reinicia o processo de abertura.
                                // Caso contrário, a requisição para o andar 1 é atendida e a máquina retorna ao
                                // estado ELEVADOR_PARADO.
                                //--------------------------------------------------------------------------
                                PORTA_FECHADA: begin
                                    lista_porta[3:2] <= MOTOR_PARADO;
                                    motor_porta <= MOTOR_PARADO;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        // Após fechar, confirma o atendimento da requisição e retorna ao estado parado
                                        if (!openDoor) begin
                                            requisicoes_andares[1] <= 0;
                                            sub_maquina <= ELEVADOR_PARADO;
                                        end
                                    end
                                end
                            endcase
                        end    
                    end else begin
                        //----------------------------------------------------------------------
                        // Controle do motor do elevador para movimentação entre andares
                        //----------------------------------------------------------------------
                        case (motor)
                            // Estado: 2'b00
                            // Se houver requisição para qualquer andar (do 1, 3 ao 5), inicia o movimento do motor.
                            // Caso contrário, mantém o motor desligado.
                            2'b00: begin
                                if (|requisicoes_andares[4:2]) begin
                                    motor <= 2'b01;   // Liga o motor para iniciar o deslocamento
                                    saida <= 2'b01;   // Sinaliza que o motor está ativo
                                end else if (|requisicoes_andares[0:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                              end
                          
                            2'b01: begin
                                if (|requisicoes_andares[4:2]) begin
                                  	motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[0:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 0;
                                    saida <= 0;
                                end
                            end
                            2'b10: begin
                                if (|requisicoes_andares[4:2]) begin
                                    motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[0:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                            end
                        endcase
                    end
                end
//==============================================================
// ANDAR_3 - Lógica para o 3º Andar
//==============================================================
                ANDAR3: begin
                    // Se a porta deve ser aberta ou existe uma requisição para o 1º andar
                    if (openDoor || requisicoes_andares[2]) begin
                        // Garante que o motor do elevador esteja parado enquanto a porta opera
                        motor <= 0;
                        // Verifica se o motor está realmente desligado (saída confirmada)
                        if (!motor) begin
                            // Máquina de estados interna para o controle da porta
                            case (sub_maquina)
                                //--------------------------------------------------------------------------
                                // Estado: ELEVADOR_PARADO
                                // Verifica se o sensor da porta fechada está inativo (indicando que a
                                // porta pode começar a abrir). Caso contrário, sinaliza alerta.
                                //--------------------------------------------------------------------------
                                ELEVADOR_PARADO: begin
                                    if (sensores_portasF[2]) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        alerta <= 1;
                                        // Permanece no mesmo estado se houver inconsistência
                                        sub_maquina <= sub_maquina;
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABRINDO
                                // Verifica se os sensores indicam que a porta está em movimento (ambos
                                // sensores de porta aberta e fechada inativos). Enquanto isso, aciona o
                                // motor da porta para o movimento de abertura.
                                //--------------------------------------------------------------------------
                                PORTA_ABRINDO: begin
                                  	lista_porta[5:4] <= 2'b01;
                                  	motor_porta <= MOTOR_ABRINDO_PORTA;
                                  	sub_maquina <= PORTA_ABERTA;
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABERTA
                                // A porta está aberta. Se houver nova requisição (botão openDoor), o
                                // contador de tempo é reiniciado. Se o tempo exceder o limite (Tempo_Porta)
                                // ou se o botão closeDoor for pressionado, inicia o fechamento da porta.
                                // Caso contrário, mantém a porta parada.
                                //--------------------------------------------------------------------------
                                PORTA_ABERTA: begin
                                    if (openDoor) begin
                                        count_tempo_porta <= 0;  // Reinicia o contador para manter a porta aberta
                                    end else begin
                                      if(sensores_portasA[2]) begin
                                        if (count_tempo_porta > Tempo_Porta || closeDoor) begin
                                            sub_maquina <= PORTA_FECHANDO;
                                            count_tempo_porta <= 0;  // Reinicia o contador para o ciclo de fechamento
                                        end else begin
                                            motor_porta <= MOTOR_PARADO;
                                          	lista_porta[5:4] <= 2'b00;
                                            count_tempo_porta++;
                                        end
                                      end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHANDO
                                // Inicia o fechamento da porta. Se, durante o fechamento, o botão openDoor for
                                // pressionado, reverte a ação voltando para abertura. Enquanto a porta estiver
                                // em movimento de fechamento, aciona o motor correspondente. Quando o sensor
                                // indicar porta fechada, muda para o estado PORTA_FECHADA.
                                //--------------------------------------------------------------------------
                                PORTA_FECHANDO: begin
                                  	lista_porta[5:4] <= 2'b10;
                                  	motor_porta <= MOTOR_FECHANDO_PORTA;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        if (sPfI) begin
                                            sub_maquina <= PORTA_FECHADA;
                                        end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHADA
                                // A porta está completamente fechada. Garante que o motor da porta esteja
                                // parado. Se o botão openDoor for pressionado, reinicia o processo de abertura.
                                // Caso contrário, a requisição para o andar 1 é atendida e a máquina retorna ao
                                // estado ELEVADOR_PARADO.
                                //--------------------------------------------------------------------------
                                PORTA_FECHADA: begin
                                    lista_porta[5:4] <= MOTOR_PARADO;
                                    motor_porta <= MOTOR_PARADO;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        // Após fechar, confirma o atendimento da requisição e retorna ao estado parado
                                        if (!openDoor) begin
                                            requisicoes_andares[2] <= 0;
                                            sub_maquina <= ELEVADOR_PARADO;
                                        end
                                    end
                                end
                            endcase
                        end
                    end else begin
                        //----------------------------------------------------------------------
                        // Controle do motor do elevador para movimentação entre andares
                        //----------------------------------------------------------------------
                        case (motor)
                            // Estado: 2'b00
                            // Se houver requisição para qualquer andar (do 1, 2, 4 ao 5), inicia o movimento do motor.
                            // Caso contrário, mantém o motor desligado.
                            2'b00: begin
                                if (|requisicoes_andares[4:3]) begin
                                    motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[1:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                            end
                            2'b01: begin
                                if (|requisicoes_andares[4:3]) begin
                                    motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[1:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                            end
                            2'b10: begin
                                if (|requisicoes_andares[4:3]) begin
                                    motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[1:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end 
                            end
                        endcase
                    end
                end
//==============================================================
// ANDAR_4 - Lógica para o 4º Andar
//==============================================================
                ANDAR4: begin
                    // Se a porta deve ser aberta ou existe uma requisição para o 1º andar
                    if (openDoor || requisicoes_andares[3]) begin
                        // Garante que o motor do elevador esteja parado enquanto a porta opera
                        motor <= 0;                      
                        // Verifica se o motor está realmente desligado (saída confirmada)
                        if (!motor) begin
                            // Máquina de estados interna para o controle da porta
                            case (sub_maquina)
                                //--------------------------------------------------------------------------
                                // Estado: ELEVADOR_PARADO
                                // Verifica se o sensor da porta fechada está inativo (indicando que a
                                // porta pode começar a abrir). Caso contrário, sinaliza alerta.
                                //--------------------------------------------------------------------------
                                ELEVADOR_PARADO: begin
                                    if (sensores_portasF[3]) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        alerta <= 1;
                                        // Permanece no mesmo estado se houver inconsistência
                                        sub_maquina <= sub_maquina;
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABRINDO
                                // Verifica se os sensores indicam que a porta está em movimento (ambos
                                // sensores de porta aberta e fechada inativos). Enquanto isso, aciona o
                                // motor da porta para o movimento de abertura.
                                //--------------------------------------------------------------------------
                                PORTA_ABRINDO: begin
                                  	lista_porta[7:6] <= 2'b01;
                                  	motor_porta <= MOTOR_ABRINDO_PORTA;
                                  	sub_maquina <= PORTA_ABERTA;
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABERTA
                                // A porta está aberta. Se houver nova requisição (botão openDoor), o
                                // contador de tempo é reiniciado. Se o tempo exceder o limite (Tempo_Porta)
                                // ou se o botão closeDoor for pressionado, inicia o fechamento da porta.
                                // Caso contrário, mantém a porta parada.
                                //--------------------------------------------------------------------------
                                PORTA_ABERTA: begin
                                    if (openDoor) begin
                                        count_tempo_porta <= 0;  // Reinicia o contador para manter a porta aberta
                                    end else begin
                                      if(sensores_portasA[3]) begin
                                        if (count_tempo_porta > Tempo_Porta || closeDoor) begin
                                            sub_maquina <= PORTA_FECHANDO;
                                            count_tempo_porta <= 0;  // Reinicia o contador para o ciclo de fechamento
                                        end else begin
                                            motor_porta <= MOTOR_PARADO;
                                          	lista_porta[7:6] <= 2'b00;
                                            count_tempo_porta++;
                                        end
                                      end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHANDO
                                // Inicia o fechamento da porta. Se, durante o fechamento, o botão openDoor for
                                // pressionado, reverte a ação voltando para abertura. Enquanto a porta estiver
                                // em movimento de fechamento, aciona o motor correspondente. Quando o sensor
                                // indicar porta fechada, muda para o estado PORTA_FECHADA.
                                //--------------------------------------------------------------------------
                                PORTA_FECHANDO: begin
                                  	lista_porta[7:6] <= 2'b10;
                                  	motor_porta <= MOTOR_FECHANDO_PORTA;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        if (sPfI) begin
                                            sub_maquina <= PORTA_FECHADA;
                                        end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHADA
                                // A porta está completamente fechada. Garante que o motor da porta esteja
                                // parado. Se o botão openDoor for pressionado, reinicia o processo de abertura.
                                // Caso contrário, a requisição para o andar 1 é atendida e a máquina retorna ao
                                // estado ELEVADOR_PARADO.
                                //--------------------------------------------------------------------------
                                PORTA_FECHADA: begin
                                    lista_porta[7:6] <= MOTOR_PARADO;
                                    motor_porta <= MOTOR_PARADO;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        // Após fechar, confirma o atendimento da requisição e retorna ao estado parado
                                        if (!openDoor) begin
                                            requisicoes_andares[3] <= 0;
                                            sub_maquina <= ELEVADOR_PARADO;
                                        end
                                    end
                                end
                            endcase
                        end    
                    end else begin
                        //--------------------------------------------------------------------------
                        // Controle do motor do elevador para movimentação entre andares
                        //--------------------------------------------------------------------------
                        case (motor)
                            // Estado: 2'b00
                            // Se houver requisição para qualquer andar (do 1 ao 3 ou 5), inicia o movimento do motor.
                            // Caso contrário, mantém o motor desligado.
                            2'b00: begin
                                if (|requisicoes_andares[4:4]) begin
                                    motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[2:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                            end
                            2'b01: begin
                                if (|requisicoes_andares[4:4]) begin
                                    motor <= 2'b01;
                                    saida <= 2'b01;
                                end else if (|requisicoes_andares[2:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                            end
                        endcase
                    end
                end

//==============================================================
// ANDAR_5 - Lógica para o 5º Andar
//==============================================================
                ANDAR5: begin
                    // Se a porta deve ser aberta ou existe uma requisição para o 1º andar
                    if (openDoor || requisicoes_andares[4]) begin
                        // Garante que o motor do elevador esteja parado enquanto a porta opera
                        motor <= 0;                      
                      // Verifica se o motor está realmente desligado saída confirmada
                        if (!motor) begin
                            // Máquina de estados interna para o controle da porta
                            case (sub_maquina)
                                //--------------------------------------------------------------------------
                                // Estado: ELEVADOR_PARADO
                                // Verifica se o sensor da porta fechada está inativo (indicando que a
                                // porta pode começar a abrir). Caso contrário, sinaliza alerta.
                                //--------------------------------------------------------------------------
                                ELEVADOR_PARADO: begin
                                  	if (sensores_portasF[4]) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        alerta <= 1;
                                        // Permanece no mesmo estado se houver inconsistência
                                        sub_maquina <= sub_maquina;
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABRINDO
                                // Verifica se os sensores indicam que a porta está em movimento (ambos
                                // sensores de porta aberta e fechada inativos). Enquanto isso, aciona o
                                // motor da porta para o movimento de abertura.
                                //--------------------------------------------------------------------------
                                PORTA_ABRINDO: begin
                                  	motor_porta <= MOTOR_ABRINDO_PORTA;
                                  	lista_porta[9:8] <= 2'b01;
                                  	sub_maquina <= PORTA_ABERTA;
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_ABERTA
                                // A porta está aberta. Se houver nova requisição (botão openDoor), o
                                // contador de tempo é reiniciado. Se o tempo exceder o limite (Tempo_Porta)
                                // ou se o botão closeDoor for pressionado, inicia o fechamento da porta.
                                // Caso contrário, mantém a porta parada.
                                //--------------------------------------------------------------------------
                                PORTA_ABERTA: begin
                                    if (openDoor) begin
                                        count_tempo_porta <= 0;  // Reinicia o contador para manter a porta aberta
                                    end else begin
                                      if(sensores_portasA[4]) begin
                                        if (count_tempo_porta > Tempo_Porta || closeDoor) begin
                                            sub_maquina <= PORTA_FECHANDO;
                                            count_tempo_porta <= 0;  // Reinicia o contador para o ciclo de fechamento
                                        end else begin
                                            motor_porta <= MOTOR_PARADO;
                                          	lista_porta[9:8] <= 2'b00;
                                            count_tempo_porta++;
                                        end
                                      end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHANDO
                                // Inicia o fechamento da porta. Se, durante o fechamento, o botão openDoor for
                                // pressionado, reverte a ação voltando para abertura. Enquanto a porta estiver
                                // em movimento de fechamento, aciona o motor correspondente. Quando o sensor
                                // indicar porta fechada, muda para o estado PORTA_FECHADA.
                                //--------------------------------------------------------------------------
                                PORTA_FECHANDO: begin
                                  	lista_porta[9:8] <= 2'b10;
                                  	motor_porta <= MOTOR_FECHANDO_PORTA;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        if (sPfI) begin
                                            sub_maquina <= PORTA_FECHADA;
                                        end
                                    end
                                end

                                //--------------------------------------------------------------------------
                                // Estado: PORTA_FECHADA
                                // A porta está completamente fechada. Garante que o motor da porta esteja
                                // parado. Se o botão openDoor for pressionado, reinicia o processo de abertura.
                                // Caso contrário, a requisição para o andar 1 é atendida e a máquina retorna ao
                                // estado ELEVADOR_PARADO.
                                //--------------------------------------------------------------------------
                                PORTA_FECHADA: begin
                                    lista_porta[9:8] <= MOTOR_PARADO;
                                    motor_porta <= MOTOR_PARADO;
                                    if (openDoor) begin
                                        sub_maquina <= PORTA_ABRINDO;
                                    end else begin
                                        // Após fechar, confirma o atendimento da requisição e retorna ao estado parado                              								
                                      	requisicoes_andares[4] = 0;
                                        sub_maquina <= ELEVADOR_PARADO;
                                    end
                                end
                            endcase
                        end    
                    end else begin
                        //--------------------------------------------------------------------------
                        // Controle do motor do elevador para movimentação entre andares
                        //--------------------------------------------------------------------------
                        case (motor)
                            // Estado: 2'b00
                            // Se houver requisição para qualquer andar (do 1 ao 4), inicia o movimento do motor.
                            // Caso contrário, mantém o motor desligado.
                            2'b00: begin
                                if (|requisicoes_andares[3:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 0;
                                    saida <= 0;
                                end
                            end
                            2'b10: begin
                                if (|requisicoes_andares[3:0]) begin
                                    motor <= 2'b10;
                                    saida <= 2'b10;
                                end else begin
                                    motor <= 2'b00;
                                    saida <= 2'b00;
                                end
                            end
                        endcase
                    end
                end
            endcase
            end
        end
    end
    end

/**********************************************************************************************/

/************************************* ALWAYS DOS BOTÕES **************************************/

// Captura do botão interno do 1º andar
always @(posedge bi1) begin
  if (andar_anterior[0] == 1 && !reset_rotina && potencia && !requisicoes_andares[0]) begin
        case (saida)
            2'b01: begin
                @(pavimento_atual[1])
                    requisicoes_andares[0] <= 1;
            end
            2'b00: begin
                requisicoes_andares[0] <= 1;
            end
        endcase
    end else begin
        requisicoes_andares[0] <= 1;
    end
end

// Captura do botão interno do 2º andar
always @(posedge bi2) begin
  if (andar_anterior[1] == 1 && !reset_rotina && potencia && !requisicoes_andares[1]) begin
        case (saida)
            2'b01: begin
                @(pavimento_atual[2])
                    requisicoes_andares[1] <= 1; 
            end
            2'b10: begin
                @(pavimento_atual[0])
                    requisicoes_andares[1] <= 1;
            end
            2'b00: begin
                requisicoes_andares[1] <= 1;
            end
        endcase
    end else begin
        requisicoes_andares[1] <= 1; 
    end
end

// Captura do botão interno do 3º andar
always @(posedge bi3) begin
  if (andar_anterior[2] == 1 && !reset_rotina && potencia && !requisicoes_andares[2]) begin
        case (saida)
            2'b01: begin
                @(pavimento_atual[3])
                    requisicoes_andares[2] <= 1;
            end
            2'b10: begin
                @(pavimento_atual[1])
                    requisicoes_andares[2] <= 1;
            end
            2'b00: begin
                requisicoes_andares[2] <= 1;
            end
        endcase
    end else begin
        requisicoes_andares[2] <= 1; 
    end
end

// Captura do botão interno do 4º andar
always @(posedge bi4) begin
  if (andar_anterior[3] == 1 && !reset_rotina && potencia && !requisicoes_andares[3]) begin
        case (saida)
            2'b01: begin
                @(pavimento_atual[4])
                    requisicoes_andares[3] <= 1;
            end 
            2'b10: begin
                @(pavimento_atual[2])
                    requisicoes_andares[3] <= 1;
            end
            2'b00: begin
                requisicoes_andares[3] <= 1;
            end
        endcase
    end else begin
        requisicoes_andares[3] <= 1;        
    end
end

// Captura do botão interno do 5º andar
always @(posedge bi5) begin
  if (andar_anterior[4] == 1 && !reset_rotina && potencia && !requisicoes_andares[4]) begin
        case (saida)
            2'b10: begin
                @(pavimento_atual[3]) begin
                    requisicoes_andares[4] <= 1;
                end
            end
            2'b00: begin
                requisicoes_andares[4] <= 1;
            end
        endcase
    end else begin
        requisicoes_andares[4] <= 1; 
    end
end 

// Captura do botão externo de subida do 1º andar
always @(posedge be1UP) begin
  if (!reset_rotina && potencia && !requisicoes_andares[0]) begin
    if (be1UP && !non_stop && andar_anterior == andar_atual) begin
          case (saida)
              2'b01: begin
                  chamadas_subida[0] <= |andar_anterior[4:1] ? 1 : 0; 
                  requisicoes_andares[0] <= !|andar_anterior[4:1] ? 1 : 0; 
              end
              2'b10: begin
                  requisicoes_andares[0] <= (|andar_anterior[4:1] && !|requisicoes_andares[0:0]) ? 1 : 1;
              end
              default: requisicoes_andares[0] <= 1;
          endcase
      end else begin
          if (be1UP && non_stop) begin
              if (andar_atual[0]) begin
                  requisicoes_andares[0] <= 1;  
              end
          end
      end
  end
end

// Captura do botão externo de subida do 2º andar
always @(posedge be2UP) begin
  if (!reset_rotina && potencia && !requisicoes_andares[1]) begin
    if (be2UP && !non_stop && andar_anterior == andar_atual) begin
      case (saida)
              2'b01: begin
                  chamadas_subida[1] <= |andar_anterior[4:2] ? 1 : 0; 
                  requisicoes_andares[1] <= !|andar_anterior[4:2] ? 1 : 0; 
              end
              2'b10: begin
                chamadas_subida[1] = (|andar_anterior[4:2] && !|requisicoes_andares[1:0]) ? 1 : 1;
              end
              default: begin 
                requisicoes_andares[1] <= 1;
              end
          endcase
      end else begin
          if (be2UP && non_stop) begin
              if (andar_atual[1]) begin
                  requisicoes_andares[1] <= 1;   
              end
          end
      end
  end
end

// Captura do botão externo de subida do 3º andar
always @(posedge be3UP) begin
  if (!reset_rotina && potencia && !requisicoes_andares[2]) begin
    if (be3UP && !non_stop && !reset_rotina) begin
          case (saida)
              2'b01: begin
                  chamadas_subida[2] <= |andar_anterior[4:3] ? 1 : 0; 
                  requisicoes_andares[2] <= !|andar_anterior[4:3] ? 1 : 0; 
              end
              2'b10: begin
                  requisicoes_andares[2] <= (|andar_anterior[4:3] && !|requisicoes_andares[2:0]) ? 1 : 1;
              end
              default: requisicoes_andares[2] <= 1;
          endcase
      end else begin
          if (be3UP && non_stop) begin
             if (andar_atual[2]) begin
                  requisicoes_andares[2] <= 1; 
             end 
          end
      end
  end
end

// Captura do botão externo de subida do 4º andar
always @(posedge be4UP) begin
  if (!reset_rotina && potencia && !requisicoes_andares[3]) begin
      if (be4UP && !non_stop) begin
          case (saida)
              2'b01: begin
                  chamadas_subida[3] <= |andar_anterior[4] ? 1 : 0; 
                  requisicoes_andares[3] <= !|andar_anterior[4] ? 1 : 0; 
              end
              2'b10: begin
                  requisicoes_andares[3] <= (|andar_anterior[4] && !|requisicoes_andares[3:0]) ? 1 : 1;
              end
              default: begin 
                requisicoes_andares[3] <= 1;
              end
          endcase
      end else begin
          if(be4Down && non_stop) begin
             if(andar_atual[3]) begin
                  requisicoes_andares[3] <= 1;             
             end 
          end       
      end
  end
end

// Captura do botão externo de descida do 2º andar
always @(posedge be2Down) begin
  if (!reset_rotina && potencia && !requisicoes_andares[1]) begin
      if (be2Down && !non_stop) begin
          case (saida)
              2'b10: begin
                  chamadas_descida[1] <= |andar_anterior[2:0] ? 1 : 0; // Se há andares abaixo, ativa descida; senão, ativa chamada 
                  requisicoes_andares[1] <= !|andar_anterior[2:0] ? 1 : 0;
              end
              2'b01: begin
                  chamadas_descida[1] <= |andar_anterior[1:0] ? (!|requisicoes_andares[4:2] ? 1 : 1) : 1; // Se há andares abaixo e sem chamadas acima, ativa descida
              end
              default: requisicoes_andares[1] <= 1;
          endcase
      end else begin
          if (be2Down && non_stop) begin
              if (andar_atual[1]) begin
                  requisicoes_andares[1] <= 1;   
              end
          end
      end
  end
end

// Captura do botão externo de descida do 3º andar
always @(posedge be3Down) begin
  if(!reset_rotina && potencia && !requisicoes_andares[2]) begin
      if (be3Down && !non_stop) begin
          case (saida)
              2'b10: begin
                  chamadas_descida[2] <= |andar_anterior[3:0] ? 1 : 0; // Se há andares abaixo, ativa descida; senão, ativa chamada 
                  requisicoes_andares[2] <= !|andar_anterior[3:0] ? 1 : 0;
              end
              2'b01: begin
                  chamadas_descida[2] <= |andar_anterior[2:0] ? (!|requisicoes_andares[4:3] ? 1 : 1) : 1; // Se há andares abaixo e sem chamadas acima, ativa descida
              end
              default: requisicoes_andares[2] <= 1;
          endcase
      end else begin
          if (be3Down && non_stop) begin
             if (andar_atual[2]) begin
                  requisicoes_andares[2] <= 1;             
             end 
          end
      end
  end
end

// Captura do botão externo de descida do 4º andar
always @(posedge be4Down) begin
  if(!reset_rotina && potencia && !requisicoes_andares[3]) begin
      if (be4Down && !non_stop) begin
          case (saida)
              2'b10: begin
                  chamadas_descida[3] <= |andar_anterior[4:0] ? 1 : 0; // Se há andares abaixo, ativa descida; senão, ativa chamada 
                  requisicoes_andares[3] <= !|andar_anterior[4:0] ? 1 : 0;
              end
              2'b01: begin
                  chamadas_descida[3] <= |andar_anterior[3:0] ? (!|requisicoes_andares[4:4] ? 1 : 1) : 1; // Se há andares abaixo e sem chamadas acima, ativa descida
              end
              default: requisicoes_andares[3] <= 1;
          endcase
      end else begin
          if (be4Down && non_stop) begin
             if(andar_atual[3]) begin
                  requisicoes_andares[3] <= 1;    
             end 
          end     
      end
  end
end

// Captura do botão externo de descida do 5º andar
always @(posedge be5Down) begin
  if(!reset_rotina && potencia && !requisicoes_andares[4]) begin
      if (be5Down && !non_stop) begin
          case (saida)
              2'b10: begin
                  chamadas_descida[4] <= |andar_anterior[4:0] ? 1 : 0; // Se há andares abaixo, ativa descida; senão, ativa chamada 
                  requisicoes_andares[4] <= !|andar_anterior[4:0] ? 1 : 0;
              end
              2'b01: begin
                  chamadas_descida[4] <= |andar_anterior[4:0] ? (!|requisicoes_andares[4:4] ? 1 : 1) : 1; // Se há andares abaixo e sem chamadas acima, ativa descida
              end
              default: requisicoes_andares[4] <= 1;
          endcase
      end else begin
          if (be5Down && non_stop) begin
              if(andar_atual[4]) begin
                  requisicoes_andares[4] <= 1;         
              end
          end
      end
  end
end

always @(saida) begin
    if(saida == 0 && ultimo_estado == 2'b01) begin
    requisicoes_andares |= chamadas_descida;
    chamadas_descida <= 0;
    if(!requisicoes_andares) begin
        requisicoes_andares |= chamadas_subida;
        chamadas_subida <= 0;
    end
    end
    else if(saida == 0 && ultimo_estado == 2'b10) begin
    requisicoes_andares |= chamadas_subida;
    chamadas_subida <= 0;
    if(!requisicoes_andares) begin
        requisicoes_andares |= chamadas_descida;
        chamadas_descida <= 0;
    end
    end
    ultimo_estado <= saida;
end

always @(pavimento_atual) begin
    if (pavimento_atual != 0) begin
        andar_anterior <= pavimento_atual;
    end
end

always @(andar_atual, lista_porta, sensores_portasA, sensores_portasF, motor, potencia) begin
    if (!alerta) begin
        alerta <= 0;
    end
    if (!potencia) begin
        //$display($time,"Entrou no IF: !potencia");
    end
    if ($countones(andar_atual) > 1) begin
        //$display($time,"Entrou no IF: $countones(andar_atual) > 1");
    end
    if ($countones(lista_porta) > 2) begin
        //$display($time,"Entrou no IF: $countones(lista_porta) > 2");
    end
    if ($countones(sensores_portasA[4:0]) > 1) begin
      //$display($time,"Entrou no IF: $countones(sensores_portasA[4:0]) > 1");
    end
    if ($countones(sensores_portasF[4:0]) < 4) begin
      //$display($time,"Entrou no IF: $countones(sensores_portasF[4:0]) < 4\nNumero de Sensores Ativos: %b", sensores_portasF);
    end
    if (motor != 0 && |lista_porta) begin
        //$display($time,"Entrou no IF: motor != 0 && |lista_porta");
    end
    if (!potencia
        || ($countones(andar_atual) > 1)       
        || ($countones(lista_porta) > 2)       
        || ($countones(sensores_portasA[4:0]) > 1     
        || ($countones(sensores_portasF[4:0]) < 4     
        || (motor != 0 && |lista_porta)))) begin
        alerta <= 1;
    end

    if (andar_atual != 0) begin
        case (andar_atual)
            5'b00001: begin
              if (|lista_porta[9:2]) begin
                alerta = 1;
                //$display($time,"Entrou no IF alerta |= |lista_porta[9:2];");
              end
            end
            5'b00010: begin 
              if (|lista_porta[9:4] || |lista_porta[1:0]) begin
                alerta = 1;
                //$display($time,"Entrou no IF alerta |= (|lista_porta[9:4] || |lista_porta[1:0]");
              end
            end
            5'b00100: begin
              if (|lista_porta[9:6] || |lista_porta[3:0]) begin
                alerta = 1;
                //$display($time,"Entrou no IF alerta |= (|lista_porta[9:6] || |lista_porta[3:0]");
              end
            end
            5'b01000: begin 
              if (|lista_porta[9:8] || |lista_porta[5:0]) begin
                alerta = 1;
                //$display($time,"Entrou no IF alerta |= (|lista_porta[9:8] || |lista_porta[5:0]");
              end
            end
            5'b10000: begin 
              if (|lista_porta[7:0]) begin
                alerta = 1;
                //$display($time,"Entrou no IF alerta |= |lista_porta[7:0]");
              end
            end
        endcase

      if (sensores_portasA != 0 && andar_atual != sensores_portasA[4:0]) begin 
        alerta = 1;
        //$display($time,"Entrou no IF sensores_portasA != 0 && andar_atual != sensores_portasA[4:0]");
      end
      //if (sensores_portasF != 6'b111111 && andar_atual != ~sensores_portasF[4:0]) begin 
        //alerta = 1;
        //$display($time,"Entrou no IF sensores_portasF != 6'b111111 && andar_atual != ~sensores_portasF[4:0]");
    //end
end
    if (alerta) begin
        lista_porta <= 12'b101010101010; 
    end
end

//Always Potência 

  always@(negedge potencia) begin
    if (flag_potencia) begin
        flag_potencia <= 0;
        if(|sensores_portasA) begin
            if(sensores_portasA[0]) begin
                lista_porta[1:0] <= 2'b10;
                motor_porta <= 2'b10;
                if (count_potencia > 20) begin
                    lista_porta[1:0] <= 2'b00;
                    motor_porta <= 2'b00;
                end else begin
                    count_potencia ++;
                end
            end
            if(sensores_portasA[1]) begin
                lista_porta[3:2] <= 2'b10;
                motor_porta <= 2'b10;
                if (count_potencia > 20) begin
                    lista_porta[3:2] <= 2'b00;
                    motor_porta <= 2'b00;
                end else begin
                    count_potencia ++;
                end
            end
            if(sensores_portasA[2]) begin
                lista_porta[5:4] <= 2'b10;
                motor_porta <= 2'b10;
                if (count_potencia > 20) begin
                    lista_porta[5:4] <= 2'b00;
                    motor_porta <= 2'b00;
                end else begin
                    count_potencia ++;
                end
            end
            if(sensores_portasA[3]) begin
                lista_porta[7:6] <= 2'b10;
                motor_porta <= 2'b10;
                if (count_potencia > 20) begin
                    lista_porta[7:6] <= 2'b00;
                    motor_porta <= 2'b00;
                end else begin
                    count_potencia ++;
                end
            end
            if(sensores_portasA[4]) begin
                lista_porta[9:8] <= 2'b10;
                motor_porta <= 2'b10;
                if (count_potencia > 20) begin
                    lista_porta[9:8] <= 2'b00;
                    motor_porta <= 2'b00;
                end else begin
                    count_potencia ++;
                end
            end
        end
    end
    motor <= 0;
    saida <= 0;
    @(potencia)
        flag_potencia <= 1;
    	requisicoes_andares <= 5'b00001;
        potencia_rotina <= 1;
        buffer_requisicoes <= requisicoes_andares;
        motor <= 2'b10;
        saida <= 2'b10;
    	alerta <= 0;
  end

//Always para display
  always @(alerta, pavimento_atual, non_stop) begin
    if (alerta) begin
    end else begin
    if (non_stop) begin
        display <= 4'b1111;  
    end else begin
      	case (pavimento_atual)
        ANDAR1: display <= 4'b0001;  
        ANDAR2: display <= 4'b0010;  
        ANDAR3: display <= 4'b0011;  
        ANDAR4: display <= 4'b0100;  
        ANDAR5: display <= 4'b0101;  
        default: display <= 4'b0000; 
        endcase
    end
    end
end        

always @(posedge reset or posedge clock) begin
    //if (reset) andar_atual <= ANDAR1;
    if (sA1) andar_atual <= ANDAR1;
    else if (sA2) andar_atual <= ANDAR2;
    else if (sA3) andar_atual <= ANDAR3;
    else if (sA4) andar_atual <= ANDAR4;
    else if (sA5) andar_atual <= ANDAR5;
end

endmodule


