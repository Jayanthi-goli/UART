`timescale 1ns / 1ps
module rx #(
parameter clk_freq = 1000000,
parameter baud_rate=9600
    )
    (input clk,rst,
    input rx,
    output reg done,
    output reg [7:0] rxdata);
    
    localparam clkcount = (clk_freq/baud_rate);
    integer count=0;
    integer counts=0;
    reg uclk=0;
    enum bit[1:0] {idle = 2'b00, start = 2'b01} state;
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
    
  
    
   always@(posedge uclk)
   begin
    if(rst)
    begin
      rxdata<=8'h00;
      counts<=0;
      done<=1'b0;
    end
    else begin
    case(state)
     idle:
      begin 
      rxdata<=8'h00;
      counts<=0;
      done<=1'b0;
      
      if(rx==1'b0)
      // rx..low...start of transactn..frm next cycle we shld recieve data 
      state<=start;
      else
       state<=idle;//rx is high
      end
      
      start:
      begin
        if(counts<=7)
         begin
       counts<=counts+1;
       rxdata<={rx ,rxdata[7:1]};
       //1st bit is lsbbit on rx line ...
       //right shift register ...
       //where msb bit is data on rx line...7msb values of rx data shifted
       //8th cycle : rx on lsb side
       end
       else
       begin
       counts<=0;
       done<=1'b1;
       state<=idle;//waiting for next data deception
       end
       end
  
  default: state <= idle;
  endcase
  end
  end
endmodule