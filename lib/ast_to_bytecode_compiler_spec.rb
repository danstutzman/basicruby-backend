require 'opal'
require './ast_to_bytecode_compiler'

def compile ruby_code
  parser = Opal::Parser.new
  sexp = parser.parse ruby_code
  compiler = AstToBytecodeCompiler.new
  compiler.compile_program sexp
end

describe AstToBytecodeCompiler, '#compile' do
  it 'compiles blank' do
    compile('').should == [[:result, nil]]
  end
  it 'compiles 3' do
    compile('3').should == [[:position, 1, 0], [:token, 1, 0], [:result, 3]]
  end
  it 'compiles puts 3' do
    compile('puts 3').should == [
      [:position, 1, 0], [:start_call], [:top], [:arg],
      [:token, 1, 0], [:result, :puts], [:arg],
      [:token, 1, 5], [:result, 3], [:arg],
      [:call],
    ]
  end
  it 'compiles 3; 4' do
    compile('3; 4').should == [
      [:position, 1, 0], [:token, 1, 0], [:result, 3], [:discard],
      [:position, 1, 3], [:token, 1, 3], [:result, 4],
    ]
  end
  it 'compiles (3)' do
    compile('(3)').should == [[:position, 1, 0], [:token, 1, 1], [:result, 3]]
  end
  it 'compiles x = 3' do
    compile('x = 3').should == [
      [:position, 1, 0], [:token, 1, 4], [:result, 3],
      [:token, 1, 0], [:to_var, :x],
    ]
  end
  it 'compiles x = 3; x' do
    compile('x = 3; x').should == [
      [:position, 1, 0], [:token, 1, 4], [:result, 3],
      [:token, 1, 0], [:to_var, :x], [:discard],
      [:position, 1, 7], [:token, 1, 7], [:from_var, :x],
    ]
  end
  it 'compiles x = if true then 3 end' do
    compile('x = if true then 3 end').should == [
      [:position, 1, 0],
      [:token, 1, 7], [:result, true],
      [:goto_if_not, "else_1_4"],
      [:position, 1, 17],
      [:token, 1, 17], [:result, 3],
      [:goto, "endif_1_4"],
      [:label, "else_1_4"],
      [:result, nil],
      [:label, "endif_1_4"],
      [:token, 1, 0], [:to_var, :x],
    ]
  end
  it 'compiles "1#{2}3"' do
    compile('"1#{2}3"').should == [
      [:position, 1, 1],
      [:start_call], [:result, "1"], [:arg],
      [:result, :<<], [:arg],
      [:token, 1, 4], [:result, 2], [:arg],
      [:token, 1, 6], [:result, "3"], [:arg],
      [:call],
    ]
  end
end