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