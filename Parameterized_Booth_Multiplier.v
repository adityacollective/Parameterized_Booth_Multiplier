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
