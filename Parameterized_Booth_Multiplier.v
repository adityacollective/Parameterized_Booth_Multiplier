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
