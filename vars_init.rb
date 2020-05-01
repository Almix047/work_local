def class_vars_init
  if @ctx && @doc
    true
  else
    puts 'Please initialize instance variables!'
  end
end

def find_ctx
  path = File.dirname(__FILE__) + '/ctx.rb'
  #=> ["class Ctx < Helper_Config\n", "class Ctx1 < Helper_Config\n"]
  results = @find_ctx ||= File.foreach(path).lazy.grep(/class Ctx/).to_a
  #=> ["Ctx", "Ctx1"]
  results.map { |el| el[/class (Ctx[\d]*)/, 1] }
end

def titles_ctx
  #=> ["Консервы Farmina N&D Ancestral Dog Adult Mini Boar & Apple", "Неон (голубой)"]
  titles = find_ctx.map { |el| Object.const_get(el).new.title }
  titles.push('SELECT ALL')
end

def vars_init(name)
  @ctx = Object.const_get(name).new
  @doc = @ctx.doc
end

def make_a_choice
  puts 'Enter the number of the selected line:'
  # +1 to start the array element index from 1 but not from 0
  titles_ctx.each_with_index { |el, index| puts "#{index + 1}) #{el}" }
  max_num = titles_ctx.length
  choice = gets.to_i
  if (1..max_num).include?(choice)
    if choice == max_num
      puts 'Use the following structure to iterate over all products:'
      puts "find_ctx.each do |ctx|\n"\
           "  vars_init(ctx)\n"\
           "  Insert your command(s) or call method(s)\n"
      puts 'end'
      puts 'Or use "all_choices"'
    else
      vars_init(find_ctx[choice - 1])
      puts 'Instance variable initialized'
    end
  else
    puts "!!!INVALID INPUT: (#{choice}). Only an integer from 1 to #{max_num}"
    puts '   Exit'
  end
end
