`timescale 1ns / 1ps
module tx #(
parameter clk_freq = 1000000,
parameter baud_rate=9600
    )
    (input clk,rst,
    input newd,
    input [7:0]tx_data,
    output reg tx,
    output reg donetx );
    localparam clkcount = (clk_freq/baud_rate);
    integer count=0;
    integer counts=0;
    reg uclk=0;
    enum bit[1:0] {idle = 2'b00, start = 2'b01 , transfer =2'b10,done=2'b11} state;
    ///uart clk gen
    
    always@(posedge clk)
    begin
    if(count<clkcount/2)//clk count for single bit how much time it takes...
    count<=count+1;
    else begin
    count<=0;
    uclk<=~uclk;//uclk used for bit duration..holding bit duration
    end 
    end
    
    reg[7:0] din;
    ////reset decoder
    
   always@(posedge uclk)
   begin
    if(rst)
    begin
     state<=idle;
    end
    else begin
    case(state)
     idle:
      begin 
      counts<=0;
      tx<=1'b1;//initailyy idile state high
      donetx<=1'b0;//
    
    if(newd)
    begin
     state<=transfer;
     din<=tx_data;
     tx<=1'b0;//startbit
     end
    else
     state<=idle;
    end
    
   transfer:begin
    if(counts<=7)begin //8bits of data we will send
     counts<= counts+1;
     tx<=din[counts]; //din[0]...
     state<=transfer;//for stop bit again transmission of data is needed
    end
    else
    begin
      counts<=0;
      tx<=1'b1;//stop bit
      state<= idle;
      donetx<=1'b1;
    end
    end
    
  default : state<=idle;
  endcase
  end 
  end  
    
endmodule