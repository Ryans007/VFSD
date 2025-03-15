
// Divisor de frenquencia

module clock_div( input clk, input reset, input logic [25:0] fator, output logic new_clk );

    // definir a velocidade
	 // fator = clk/ velocidade_desejada x 2
	 	 
    reg [25:0] count;
    
    always @ (posedge clk)
    begin
      if (reset) begin
         count <= 0;
      	 new_clk <= 0;
      end
      else
        if (count == (fator - 1)) begin
             count <= 0;
             new_clk <= ~new_clk;
         end
         else begin
            count <= count + 1;
            new_clk <= new_clk;
         end
    end
endmodule