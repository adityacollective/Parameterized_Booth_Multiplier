module booth_multiplier #(parameter l_word = 4)(
  output [2*l_word-1 : 0] product,
  output                  ready,
  input  [l_word-1 : 0]   word1, word2,
  input                   start, clock, reset
  );
  
  wire empty, w2_neg, m_is_1, m0, flush, load_words, shift, add, sub;
  control_unit Controller(.load_words(load_words), .flush(flush), .shift(shift), .add(add), .sub(sub), .empty(empty), .w2_neg(w2_neg));
  datapath_unit Datapath(.product(product), .empty(empty), .w2_neg(w2_neg), .m_is_1(m_is_1), .m0(m0), .word1(word1), .word2(word2), .load_words(load_words), .flush(flush), .shift(shift), .add(add), .sub(sub), .clock(clock), .reset(reset));
endmodule

module control_unit #(parameter l_word = 4, l_state = 3, l_brc = 2)(
  output reg  load_words, flush, shift, add, sub,
  output      ready,
  input       empty, w2_neg, m_is_1, m0, start, clock, reset
  );
  parameter s_idle = 0,
            s_running = 1,
            s_working = 2,
            s_shift1 = 3,
            s_shift2 = 4;
            
  reg  [l_state-1 : 0] state, next_state;
  reg                  m0_del;
  wire [l_brc-1 : 0]   brc = {m0, m0_del};
  assign ready = (state == s_idle);
        //Necessary to reset mO_del when load_words is asserted, otherwise it would start with residual value
        
  always@(posedge clock, posedge reset) begin
    if(reset) state <= s_idle;
    else      state <= next_state;
  end
  
  always@(posedge clock, posedge reset) begin
    if(reset)           m0_del <= 0;
    else if(load_words) m0_del <= 0;
    else if(shift)      m0_del <= m0; 
  end
  
  always@(state, start, brc, empty, w2_neg, m_is_1, m0) begin
    load_words = 0;
    flush = 0;
    shift = 0;
    add = 0;
    sub = 0;
    next_state = s_idle;
    case(state)
        s_idle:    begin
                     if(!start) next_state = s_idle;
                     else if(empty) begin
                                      flush = 1;
                                      next_state = s_idle;
                                    end
                     else           begin
                                      flush = 1;
                                      load_words = 1;
                                      next_state = s_running;
                                    end
                   end
        s_running: begin
                     if(m_is_1) begin
                                  if(brc == 3) begin
                                                 shift = 1;
                                                 next_state = s_shift2;
                                               end
                                  else         begin
                                                 sub = 1;
                                                 next_state = s_shift1;
                                               end
                                end
                      else      begin
                                  if(brc == 1) begin
                                                 add = 1;
                                                 next_state = s_working;
                                               end
                                  else if(brc == 2) begin
                                                 sub = 1;
                                                 next_state = s_working;
                                               end
                                  else         begin
                                                 shift = 1;
                                                 next_state = s_running;
                                               end
                                end
                   end
         s_shift1: begin
                     shift = 1;
                     next_state = s_running;
                   end
         s_shift2: begin
                     if((brc == 1) && (!w2_neg)) add = 1;
                     next_state = s_idle;
                   end
         s_working: begin
                     shift = 1;
                     next_state = s_running;
                   end
         default: next_state = s_idle;
     endcase
  end
  endmodule
  
  module datapath_unit #(parameter l_word = 4)(
    output reg [2*l_word-1 : 0] product,
    output empty, w2_neg, m_is_1, m0,
    input  [l_word-1 : 0] word1, word2,
    input load_words, flush, shift, add, sub, clock, reset
  );
    reg [2*l_word-1 : 0] multiplicand;
    reg [l_word-1 : 0] multiplier;
    reg flag;
    
    assign empty = ((word1 == 0) || (word2 == 0));
    assign w2_neg = flag;
    assign m_is_1 = (multiplier == 1);
    assign m0 = multiplier[0];
    
    parameter all_ones = {l_word{1'b1}};
    parameter all_zeros = {l_word{1'b0}};
    
    always@(posedge clock, posedge reset) begin
        if(reset) begin
            multiplier <= 0;
            multiplicand <= 0;
            product <= 0;
            flag <= 0;
        end
        else begin
            if(load_words) begin
                flag = word2[l_word - 1];
                if(word1[l_word - 1] == 0) multiplicand <= word1;
                else multiplicand <= {all_ones, word1[l_word - 1 : 0]};
                multiplier <= word2;
            end
            
            if(flush) begin
                product <= 0;
                if(shift) begin
                    multiplier <= multiplier >> 1;
                    multiplicand <= multiplicand << 1;
                end
                if(add) begin
                    product <= product + multiplicand;
                end
                if(sub) begin
                    product <= product - multiplicand;
                end
            end
            
        end
    end
    
  endmodule