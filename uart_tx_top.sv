
`timescale 1ns / 1ps
 
 
///////////////////////// LCR is used in TX  
// 16x oversampling
  
module uart_tx_top(
input clk, rst, baud_pulse, pen, thre, stb, sticky_parity, eps, set_break,
input [7:0] din,// frm fifo
input [1:0] wls,
output reg pop, sreg_empty,tx
);
  
  
typedef enum logic [1:0] {idle = 0, start = 1 , send = 2 , parity = 3} state_type;
state_type state = idle;   
    
 reg [7:0] shft_reg;
 reg tx_data;//data needs to be transmitted on tx line 
 reg d_parity;//(xor of all bit count)
 reg [2:0] bitcnt = 0;//max bitcount=8 so 3 bot req
 reg [4:0] count = 5'd15;//s.b has max count upto 32 so 5bit size
 reg parity_out;
 
 
 always@(posedge clk, posedge rst)
 begin
     if(rst)
       begin
       state  <= idle;
       count  <= 5'd15;
       bitcnt <= 0;
       ///////////////
       shft_reg   <= 8'bxxxxxxxx;
       pop        <= 1'b0;//dont wanna read data
       sreg_empty <= 1'b0;//shiftreg is not empty ..have value
       tx_data    <= 1'b1; //idle value
       
       end
     else if(baud_pulse)
     //s.b ; data but,parity: 16cycles of bclk, stop :max2 32cycles of sclk
        begin
           case(state)
           ////////////// idle state
             idle: 
              begin
                if(thre == 1'b0) ///csr.lsr.thre
                //THRE = Transmit Holding Register Empty
                begin 
                    if(count != 0)//16cycles not done
                      begin
                      count <= count - 1;
                      state <= idle;
                      end
                    else
                      begin
                      count <= 5'd15;
                      state <= start;
                      bitcnt  <= {1'b1,wls};
                      
                      /////////////////////////
                    //send to fifo and read frm there  
                         pop         <= 1'b1;  ///read tx fifo
                         shft_reg    <= din;   /// store fifo data in shift reg
                         sreg_empty  <= 1'b0;
                         
                         
                        /////////////////////////////////
                         //start of transaction                     
                         tx_data <= 1'b0; ///start bit 
                      end
                 end
              end
             
             /////////////start state
             start: 
               begin
                      /////////////// calculate parity
                        case(wls)
                         2'b00: d_parity <= ^din[4:0];
                         2'b01: d_parity <= ^din[5:0];
                         2'b10: d_parity <= ^din[6:0];
                         2'b11: d_parity <= ^din[7:0];             
                         endcase
                      
                      
            //Bit 0 starts immediately,Then count runs from 15 → 0, That holds bit0 for 16 cycles
             //So bit0 does NOT need to be counted in bitcnt
                    //count =0 ,done with 16cycles...    
                        
                     if( count != 0)
                      begin
                      count <= count - 1;
                      state <= start;
                      end
                    else
                      begin
                      count  <= 5'd15;
                      state  <= send;
                      /////////////////////////////
                      
                      tx_data    <= shft_reg[0]; 
                      shft_reg   <= shft_reg >> 1; 
                      ////////////////////////
                      pop        <= 1'b0;
                      end
               end
           ///////////////// send state
             send: 
               begin
               
                       case({sticky_parity, eps})
                       //d_parity = 1 → number of 1s in data is odd
                       //d_parity = 0 → number of 1s in data is even
                        2'b00: parity_out <= ~d_parity;//odd :eps=0
                        2'b01: parity_out <= d_parity;
                        2'b10: parity_out <= 1'b1;//mark
                        2'b11: parity_out <= 1'b0;//space
                        endcase
                        
                        
                     if(bitcnt != 0)
                          begin
                                if(count != 0)
                                  begin
                                  count <= count - 1;
                                  state <= send;  
                                  end
                                else
                                  begin
                                  count <= 5'd15;//set back to 15 to start timing the next data bit
                                  bitcnt <= bitcnt - 1;
                                  tx_data    <= shft_reg[0]; 
                                  shft_reg   <= shft_reg >> 1;
                                  state <= send;
                                  end
                             end
                       else
                          begin
                                ///////////////////////////
                                if(count != 0)//for last data shkd also wait for 16cycles so
                                  begin
                                  count <= count - 1;
                                  state <= send;  
                                  end
                                else
                                  begin
                                   count <= 5'd15;
                                   sreg_empty <= 1'b1;//shifreg transmitted to tx line 
                                  
                                      if(pen == 1'b1)
                                       begin
                                         state <= parity;
                                         count <= 5'd15;
                                         tx_data <= parity_out;
                                       end  
                               ////////////////////////
                                      else
                                       begin
                                         tx_data <= 1'b1;//stop bit
                                         count   <= (stb == 1'b0 )? 5'd15 :(wls == 2'b00) ? 5'd23 : 5'd31;
                                    // stb=0,wait for 16cycles ....or depends on wls    
                                         state   <= idle;
                                         //after idle state we wait there for 16cycles needed for this stop bit 
                                       end  
                                  end
                        end/// else of bitcnt loop
               end
 
              
             parity: 
               begin
                     if(count != 0)
                      begin
                      count <= count - 1;
                      state <= parity;
                      end
                    else
                      begin
                      tx_data <= 1'b1;
                      count   <= (stb == 1'b0 )? 5'd15 :(wls == 2'b00) ? 5'd17 : 5'd31;
                      state <= idle;
                      end
               end 
               
             default: ;
            endcase   
        end
 end
 
     
////////////////////////////////////////////////////// 
always@(posedge clk, posedge rst)
begin
if(rst)
  tx <= 1'b1;
else
  tx <= tx_data & ~set_break;
  //if sb=0,tx=txdata
  //if sb=1 ,permenantly tx=0
end    
    
    
endmodule
