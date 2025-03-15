module mod_ref(
  input reset, clock, bi1, bi2, bi3, bi4, bi5, be1, be2, be3, be4, be5, s1, s2, s3, s4, s5, 
  output int saida, 
  output logic Port1, Port2, Port3, Port4, Port5, 
  output logic [3:0] pavimento);

  logic stoped;

  int motor;
  
  integer i;  

  int andar_anterior;
  
  int count_tempo;

  time time_2_final, time_2_initial;
  
  logic [4:0] requisicoes_andares;
  
  logic [4:0] lista_porta;
  assign Port1 = lista_porta[0];
  assign Port2 = lista_porta[1];
  assign Port3 = lista_porta[2];
  assign Port4 = lista_porta[3];
  assign Port5 = lista_porta[4];
  
  logic [4:0] pavimento_atual ;
  assign pavimento_atual[0] = s1;
  assign pavimento_atual[1] = s2;
  assign pavimento_atual[2] = s3;
  assign pavimento_atual[3] = s4;
  assign pavimento_atual[4] = s5;

  
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      requisicoes_andares = 5'b00001;
      motor = 0;
      saida = 0;
      lista_porta = 0;
      count_tempo = 0;
      stoped = 0;
      
    end else begin
        if (!stoped) begin
            case(pavimento_atual)
                5'b00001: begin
                    pavimento = 1;
                    if (requisicoes_andares[0]) begin
                        if (count_tempo == 0) begin
                            saida = 0;
                            motor = 0;
                            count_tempo++;
                        end else if (count_tempo >= 1 && count_tempo <= 50) begin
                            lista_porta[0] = 1;
                            count_tempo++;
                        end else if (count_tempo > 50) begin
                            lista_porta[0] = 0;
                            requisicoes_andares[0] = 0;
                            count_tempo = 0;
                        end
                    end else begin
                        case (motor)
                        0: begin
                        if (|requisicoes_andares[4:1]) begin
                            motor = 1;
                            saida = 1;
                        end else begin
                            motor = 0;
                            saida = 0;
                        end
                        end
                    endcase
                    end


                    end

                    5'b00010: begin
                    pavimento = 2;
                    if (requisicoes_andares[1]) begin
                        time_2_final = $time;
                        if (count_tempo == 0) begin
                            saida = 0;
                            motor = 0;                    
                            count_tempo++;
                        end else if (count_tempo >= 1 && count_tempo <= 50) begin
                            lista_porta[1] = 1;
                            count_tempo++;
                        end else if(count_tempo > 50) begin
                            lista_porta[1] = 0;
                            requisicoes_andares[1] = 0;
                            count_tempo = 0;
                        end
                    end else begin
                        case (motor)
                        0: begin
                            if (|requisicoes_andares[4:2]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[0:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        1: begin
                            if (|requisicoes_andares[4:2]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[0:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        -1: begin
                            if (|requisicoes_andares[4:2]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[0:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                    endcase
                    end 

                    
                    end

                    5'b00100: begin
                    pavimento = 3;
                    if (requisicoes_andares[2]) begin
                        if (count_tempo == 0) begin
                            saida = 0;
                            motor = 0;
                            count_tempo++;
                        end else if (count_tempo >= 1 && count_tempo <= 50) begin
                            lista_porta[2] = 1;
                            count_tempo++;
                        end else if (count_tempo > 50) begin
                            lista_porta[2] = 0;
                            requisicoes_andares[2] = 0;
                            count_tempo = 0;
                        end
                    end else begin
                        case (motor)
                        0: begin
                            if (|requisicoes_andares[4:3]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[1:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        1: begin
                            if (|requisicoes_andares[4:3]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[1:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        -1: begin
                            if (|requisicoes_andares[4:3]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[1:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                    endcase     
                    end

                            
                    end

                    5'b01000: begin
                    pavimento = 4;
                    if (requisicoes_andares[3]) begin
                        saida = 0;
                        if (count_tempo == 0) begin
                            saida = 0;
                            motor = 0;                    
                            count_tempo++;
                        end else if (count_tempo >= 1 && count_tempo <= 50) begin
                            lista_porta[3] = 1;
                            count_tempo++;
                        end else if (count_tempo > 50) begin
                            lista_porta[3] = 0;
                            requisicoes_andares[3] = 0;
                            count_tempo = 0;
                        end
                    end else begin
                        case (motor)
                        0: begin
                            if (|requisicoes_andares[4:4]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[2:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        1: begin
                            if (|requisicoes_andares[4:4]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[2:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        -1: begin
                            if (|requisicoes_andares[4:4]) begin
                                motor = 1;
                                saida = 1;
                            end else if (|requisicoes_andares[2:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                    endcase   
                    end

                
                    end

                    5'b10000: begin
                    pavimento = 5;
                    if (requisicoes_andares[4]) begin
                        if (count_tempo == 0) begin
                            saida = 0;
                            motor = 0;                    
                            count_tempo++;
                        end else if (count_tempo >= 1 && count_tempo <= 50) begin
                            lista_porta[4] = 1;
                            count_tempo++;
                        end else if (count_tempo > 50) begin
                            lista_porta[4] = 0;
                            requisicoes_andares[4] = 0;
                            count_tempo = 0;
                        end
                    end else begin
                        case (motor)
                        0: begin
                            if (|requisicoes_andares[3:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                        -1: begin
                            if (|requisicoes_andares[3:0]) begin
                                motor = -1;
                                saida = -1;
                            end else begin
                                motor = 0;
                                saida = 0;
                            end
                        end
                    endcase
                    end
                    end
                endcase
                end
        end
end


  always @(posedge bi1 or posedge be1) begin
    if (andar_anterior[0] == 1) begin
        case (motor)
            1: begin
                @(pavimento_atual[1])
                    requisicoes_andares[0] = 1;
            end
            0: begin
                requisicoes_andares[0] = 1;
            end
        endcase
    end else begin
        requisicoes_andares[0] = 1;
    end
    requisicoes_andares[0] = 1;
  end

  always @(posedge bi2 or posedge be2) begin
    if (andar_anterior[1] == 1) begin
        case (motor)
            1: begin
                @(pavimento_atual[2])
                    requisicoes_andares[1] = 1; 
            end
            -1: begin
                @(pavimento_atual[0])
                    requisicoes_andares[1] = 1;

            end
            0: begin
                requisicoes_andares[1] = 1;
            end

        endcase
    end else begin
        requisicoes_andares[1] = 1; 
    end
  end

  always @(posedge bi3 or posedge be3) begin
    if (andar_anterior[2] == 1) begin
        case (motor)
            1: begin
                @(pavimento_atual[3])
                    requisicoes_andares[2] = 1;
            end
            -1: begin
                @(pavimento_atual[1])
                    requisicoes_andares[2] = 1;
            end
            0: begin
                requisicoes_andares[2] = 1;
            end
        endcase
    end else begin
        requisicoes_andares[2] = 1; 
    end
  end
  always @(posedge bi4 or posedge be4) begin
    if (andar_anterior[3] == 1) begin
        case (motor)
            1: begin
                @(pavimento_atual[4])
                    requisicoes_andares[3] = 1;
            end 
            -1: begin
                @(pavimento_atual[2])
                    requisicoes_andares[3] = 1;
            end
            0: begin
                requisicoes_andares[3] = 1;
            end
            
        endcase
    end else begin
        requisicoes_andares[3] = 1;        
    end
  end

  always @(posedge bi5 or posedge be5) begin
    if (andar_anterior[4] == 1) begin
        case (motor)
            -1: begin
                @(pavimento_atual[3]) begin
                    requisicoes_andares[4] = 1;
                end
            end
            0: begin
                requisicoes_andares[4] = 1;
            end
        endcase
    end else begin
        requisicoes_andares[4] = 1; 
    end
  end 
  
  always @(pavimento_atual) begin
    if (pavimento_atual != 0) begin
        andar_anterior = pavimento_atual;
    end
  end

  
always @(posedge clock) begin
    integer count; // Declaração da variável dentro do bloco
    count = 0;     // Inicializa a contagem

    // Conta os bits '1' na variável pavimento_atual
    for (i = 0; i < $bits(pavimento_atual); i = i + 1) begin
        if (pavimento_atual[i]) begin
            count = count + 1;
        end
    end

    // Verifica se há mais de um bit ativo
    if (count > 1) begin
        stoped = 1;
    end else begin
        stoped = 0;
    end
end

endmodule



    

  
  
 






