require 'opal'
require './ast_to_bytecode_compiler'
require './bytecode_interpreter'

$main = self

def output_of ruby_code
  parser = Opal::Parser.new
  sexp = parser.parse ruby_code
  compiler = AstToBytecodeCompiler.new $main
  bytecodes = compiler.compile sexp
  output = ''
  interpreter = BytecodeInterpreter.new $main, bytecodes
  interpreter.set_output_handler { |new_output|
    output += new_output
  }
  interpreter.run
  output
end

describe BytecodeInterpreter, '#run' do
  it 'runs puts 3' do
    output_of('puts 3').should == "3\n"
  end
  it 'runs puts 3; puts 4' do
    output_of('puts 3; puts 4').should == "3\n4\n"
  end
  it 'runs puts 3\nputs 4' do
    output_of("puts 3\nputs 4").should == "3\n4\n"
  end
  it 'runs puts 3 + 4' do
    output_of("puts 3 + 4").should == "7\n"
  end
  it 'runs puts 3 + 4 + 5' do
    output_of("puts 3 + 4 + 5").should == "12\n"
  end
  it 'runs puts 3 + (4 + 5)' do
    output_of("puts 3 + (4 + 5)").should == "12\n"
  end

  it 'runs p nil' do
    output_of("p nil").should == "nil\n"
  end
  it 'runs p 3' do
    output_of("p 3").should == "3\n"
  end
  it 'runs p 3, 4' do
    output_of("p 3, 4").should == "3\n4\n"
  end
  it 'runs p p' do
    output_of("p p").should == "nil\n"
  end
  it 'runs p p 3' do
    output_of("p p 3").should == "3\n3\n"
  end
  it 'runs p p 3, 4' do
    output_of("p p 3, 4").should == "3\n4\n[3, 4]\n"
  end

  it 'runs x = 3 \n p x' do
    output_of("x = 3\np x").should == "3\n"
  end
  it 'raises NameError from p x' do
    expect { output_of("p x") }.to raise_exception(NameError)
  end
  it 'prints main from puts to_s' do
    output_of("puts to_s").should == "main\n"
  end

  it 'runs puts "3#{4}5"' do
    output_of('puts "3#{4}5"').should == "345\n"
  end

  it 'runs if true \n p 3 \n p4 \n end \n p 5' do
    output_of("if true \n p 3 \n p 4 \n end \n p 5").should == "3\n4\n5\n"
  end
  it 'runs if true \n p 3 \n end' do
    output_of("if true \n p 3 \n end").should == "3\n"
  end
  it 'runs if true \n p 3 \n end \n p 4' do
    output_of("if true \n p 3 \n end \n p 4").should == "3\n4\n"
  end
  it 'runs if false \n p 3 \n p4 \n end \n p 5' do
    output_of("if false \n p 3 \n p 4 \n end \n p 5").should == "5\n"
  end
  it 'runs if false \n p 3 \n end' do
    output_of("if false \n p 3 \n end").should == ""
  end
  it 'runs if false \n p 3 \n end \n p 4' do
    output_of("if false \n p 3 \n end \n p 4").should == "4\n"
  end
  it 'runs if true \n end \n' do
    output_of("if true \n end").should == ""
  end
  it 'runs if true \n end \n p 3' do
    output_of("if true \n end \n p 3").should == "3\n"
  end

  it 'runs if true \n p 3 \n else \n p 4 \n end \n p 5' do
    output_of("if true \n p 3 \n else \n p 4 \n end \n p 5").should ==
      "3\n5\n"
  end
  it 'runs if false \n p 3 \n else \n p 4 \n end \n p 5' do
    output_of("if false \n p 3 \n else \n p 4 \n end \n p 5").should ==
      "4\n5\n"
  end

  it 'runs if true \n p 3 \n elsif false \n p 4 \n end' do
    output_of("if true \n p 3 \n elsif false \n p 4 \n end").should == "3\n"
  end
  it 'runs if false \n p 3 \n elsif true \n p 4 \n end' do
    output_of("if false \n p 3 \n elsif true \n p 4 \n end").should == "4\n"
  end
  it 'runs if false \n p 3 \n elsif false \n p 4 \n end' do
    output_of("if false \n p 3 \n elsif false \n p 4 \n end").should == ""
  end
  it 'runs if true \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end' do
    output_of("if true \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end"
      ).should == "3\n"
  end
  it 'runs if false \n p 3 \n elsif true \n p 4 \n else \n p 5 \n end' do
    output_of("if false \n p 3 \n elsif true \n p 4 \n else \n p 5 \n end"
      ).should == "4\n"
  end
  it 'runs if false \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end' do
    output_of("if false \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end"
      ).should == "5\n"
  end

  it 'runs x = if true then 3 end; p x' do
    output_of("x = if true then 3 end; p x").should == "3\n"
  end
  it 'runs x = if false then 3 end; p x' do
    output_of("x = if false then 3 end; p x").should == "nil\n"
  end

end
