class BytecodeInterpreter
  class ResultIsUnassigned
  end

  class ProgramTerminated < RuntimeError
  end

  attr_accessor :pos, :partial_calls, :step_output, :result

  def initialize main, hash
    @main = main
    @hash = hash
    @step_output = nil
    @pos = hash[:start]
    @partial_calls = []
    @result = ResultIsUnassigned
  end

  def run
    all_output = ''
    while @pos
      step
      all_output += @step_output
    end
    all_output
  end

  def step
    raise "No more instructions" if @pos.nil?
    @step_output = ''
    begin
      bytecodes = @hash[@pos]
      bytecodes.each do |bytecode|
        head, arg0 = bytecode
        case head
          when :start_call
            @partial_calls.push []
          when :arg
            @partial_calls.last.push result
          when :int
            @result = arg0
          when :nil
            @result = nil
          when :call
            do_call arg0
          when :done
            @pos = nil
          when :goto
            @result = ResultIsUnassigned
            @pos = arg0
          else
            raise "Unknown bytecode head #{head}"
        end
      end
    rescue ProgramTerminated => e
      @step_output += "#{e.message}\n"
      @pos = nil
    end
  end

  def do_call method_name
    receiver, *args = @partial_calls.pop
    if receiver == ResultIsUnassigned && method_name == :puts
      if args.size == 0
        @step_output += "\n"
      else
        @step_output += args.map { |arg| "#{arg}\n" }.join
      end
      @result = nil
    elsif receiver == ResultIsUnassigned && method_name == :p
      if args.size == 0
        @result = nil
      elsif args.size == 1
        @step_output += "#{args[0].inspect}\n"
        @result = args[0]
      else
        @step_output += args.map { |arg| "#{arg.inspect}\n" }.join
        @result = args
      end
    else
      begin
        if receiver == ResultIsUnassigned
          receiver = @main
        end
        if receiver.private_methods.include?(method_name)
          message = "private method `#{method_name}' called for " +
            "#{receiver.inspect}:#{receiver.class}"
          raise NoMethodError.new(message)
        else
          @result = receiver.send method_name, *args
        end
      rescue NoMethodError => e
        raise ProgramTerminated.new e
      end
    end
  end
end