# garfield
def prepare_json
  if class_vars_init
    script = @ctx.todo_js.find { |str| str.include?('JCCatalogElement') }
    data = script[/new JCCatalogElement\(({.+})/, 1].tr("'", '"')
    JSON.parse(data)
  else
    make_a_choice
  end
end

def line_by_line(input)
  input.each { |el| puts el } if input.is_a?(Array)
  input.each { |key, val| puts "#{key}: #{val}" } if input.is_a?(Hash)
end

def all_choices
  find_ctx.each do |ctx|
    vars_init(ctx)
    # Insert your command(s) or call method(s)
  end
end
