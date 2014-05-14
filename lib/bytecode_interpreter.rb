if RUBY_PLATFORM != 'opal'
  send :require, './interpreter_state'
else
  require 'interpreter_state.rb'

  def gets
    `window.$stdin_is_waiting = true;`
  end
end

$captured_stdout = []
$is_capturing_stdout = false
class <<$stdout
  alias :old_write :write
  def write *args
    if $is_capturing_stdout
      if RUBY_PLATFORM == 'opal'
        args.each { |arg| $captured_stdout.push arg + "\n" }
      else
        args.each { |arg| $captured_stdout.push arg }
      end
    else
      old_write *args
    end
  end
end

class String
  def <<(*args)
    self + args.map { |arg| "#{arg}" }.join
  end
end

class BytecodeInterpreter
  def initialize
    @partial_calls = []
    @num_partial_call_executing = nil
    @result = [] # a stack with 0 or 1 items in it
    @vars = {}
    @started_var_names = []
    @main = (RUBY_PLATFORM == 'opal') ?
      `Opal.top` : TOPLEVEL_BINDING.eval('self')
    @accepting_input = false
    @accepted_input = nil

    $captured_stdout = []
  end

  def visible_state
    {
      partial_calls: @partial_calls,
      started_var_names: @started_var_names,
      vars: @vars,
      output: $captured_stdout,
      num_partial_call_executing: @num_partial_call_executing,
      accepting_input: @accepting_input,
    }
  end

  def is_result_truthy?
    @result[0] && !!@result[0]
  end

  def interpret bytecode #, speed, stdin
    case bytecode[0]
      when :result
        result_is bytecode[1]
        0
      when :discard
        pop_result
        0
      when :start_call
        @partial_calls.push []
        200
      when :top
        result_is @main
        0
      when :arg
        @partial_calls.last.push pop_result
        if @partial_calls.last.last == @main
          0 # don't dwell on it, because user didn't specify it
        else
          800
        end
      when :pre_call
        @num_partial_call_executing = @partial_calls.size - 1
        if @partial_calls.last == [@main, :gets]
          @accepting_input = true
          30 * 1000
        else
          400
        end
      when :call
        @num_partial_call_executing = nil
        call = @partial_calls.pop
        outputs = $captured_stdout.size
        if @accepted_input != nil
          result_is @accepted_input
          @accepted_input = nil
        else
          result_is do_call *call
        end
        if $captured_stdout.size > outputs
          800
        else
          0
        end
      when :start_var
        @started_var_names.push bytecode[1]
        0
      when :to_var
        var_name = bytecode[1]
        @started_var_names = @started_var_names - [var_name]
        value = pop_result
        @vars[var_name] = value
        result_is value
        0
      when :from_var
        var_name = bytecode[1]
        out = @vars[var_name]
        result_is out
        0
      when :make_symbol
        result = pop_result
        `result.is_symbol = true;` if RUBY_PLATFORM == 'opal'
        result_is result
        0
      when :goto_if_not
        pop_result
        0
    end
  end

  def set_input text
    @accepted_input = text
    @accepting_input = false
  end

  private

  def result_is new_result
    @result.push new_result
    raise "Result stack has too many items: #{@result}" if @result.size > 1
  end

  def do_call receiver, method_name, *args
    if receiver == @main
      begin
        $is_capturing_stdout = true
        result = @main.send method_name, *args
        $is_capturing_stdout = false
        result
      rescue NoMethodError => e
        raise NameError.new "undefined local variable or method " +
          "`#{method_name}' for main:Object"
      end
    else
      $is_capturing_stdout = true
      result = receiver.send(method_name, *args)
      $is_capturing_stdout = false
      result
    end
  end

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end
end
