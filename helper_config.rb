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

def make_a_choice
  puts 'Enter the number of the selected line:'
  # +1 to start the array element index from 1 but not from 0
  titles_ctx.each_with_index { |el, index| puts "#{index + 1}) #{el}" }
  max_num = titles_ctx.length
  choice = gets.to_i
  if (1..max_num).include?(choice)
    if choice == max_num
      puts "Selected 'ALL'. Now in development."
    else
      @ctx = Object.const_get(find_ctx[choice - 1]).new
      @doc = @ctx.doc
      puts 'Instance variable initialized'
    end
  else
    puts "!!!INVALID INPUT: (#{choice})."\
         " Only an integer from 1 to #{max_num}"
  end
end

class HelperConfig
  attr_reader :title

  def initialize
    @title = doc.xpath('//div[contains(@class, "item_name_container")]/h1').text
  end

  def dup
    Marshal.load(Marshal.dump(self))
  end
end

def prepare_json
  if @ctx
    script = @ctx.todo_js.find { |str| str.include?('JCCatalogElement') }
    data = script[/new JCCatalogElement\(({.+})/, 1].tr("'", '"')
    JSON.parse(data)
  else
    puts "Please initialize instance variable '@ctx'!"
    make_a_choice
  end
end

def line_by_line(input)
  input.each { |el| puts el } if input.is_a?(Array)
  input.each { |key, val| puts "#{key}: #{val}" } if input.is_a?(Hash)
end
