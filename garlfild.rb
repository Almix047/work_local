class EducationGarfiled < Scripting::CustomParser
  def handle404(ctx)
    doc = RuleTools.doc(ctx.page_content)
    if doc.xpath('//div[@class="title_404"]/p').text.include?('Страница не найдена')
      p = {}
      p[:url] = ctx.todo[:url]
      p[DELISTED] = true
      ctx.products << p
      true
    end
    false
  end

  def parse(ctx)
    initialize_instance_variables(ctx)
    create_multi_product if product_page? && multi_products.any?
    create_single_product if product_page? && multi_products.empty?
    @ctx.products.any?
  end

  def initialize_instance_variables(ctx)
    @ctx = ctx
    @doc = ctx.doc
  end

  def product_page?
    @ctx.doc.xpath('//div[@itemtype="//schema.org/Product"]').any?
  end

  def multi_products
    @_multi_products ||= @doc.xpath('//div[@class="product-item-detail-info-section"]//li')
  end

  def create_single_product
    p = @ctx.base_product.dup
    p[NAME] = @doc.xpath('//h1[@class="bx-title"]').text
    p[SKU] = @doc.xpath('//span[@class="item_art_number"]').text
    p[PRICE] = prepare_json.dig('PRODUCT', 'ITEM_PRICES', 0, 'PRICE') if product_availability?
    p[PROMO_NAME] = 'Акция' if promo?
    p[REGULAR_PRICE] = regular_price if promo? && product_availability?
    p[STOCK] = product_availability?
    p[KEY] = @doc.xpath('//input[@name="good_id"]/@value').text + p[SKU]
    @ctx.add_product(p)
  end

  def create_multi_product
    multi_products.each do |product|
      p = @ctx.base_product.dup
      index = find_index_product(product.xpath('./@data-onevalue').text)
      p[NAME] = prepare_json.dig('OFFERS', index, 'NAME').split.join(' ')
      p[SKU] = product.xpath('./@data-art').text
      p[PRICE] = prepare_json.dig('OFFERS', index, 'ITEM_PRICES', 0, 'PRICE') if product_availability?(product)
      p[PROMO_NAME] = 'Акция' if promo?(product)
      p[REGULAR_PRICE] = regular_price(index, product) if promo?(product) && product_availability?(product)
      p[STOCK] = product_availability?(product)
      p[KEY] = product.xpath('./@data-onevalue').text + p[SKU]
      @ctx.add_product(p)
    end
  end

  def prepare_json
    script = @ctx.todo[:javascript].find { |s| s.include?('JCCatalogElement') }
    data = script[/new JCCatalogElement\(({.+})/, 1].tr("'", '"')
    JSON.parse(data)
  end

  def promo?(product = nil)
    multi_products.any? ? product.xpath('./@data-discountstatus').text.include?('discount') : @doc.xpath('//div[@class="item_discount"]').any?
  end

  def product_availability?(product = nil)
    stock = multi_products.any? ? product.xpath('./@data-availstatus').text : @doc.xpath('//@data-availstatus').text
    stock !~ /not?_avail/
  end

  def find_index_product(pid)
    pids = prepare_json['TREE_PROPS'].first['VALUES'].map { |key, _val| key }
    pids.delete('0') # Optional string
    pids.index(pid)
  end

  def base_price(index = nil)
    if multi_products.any?
      source = prepare_json.dig('OFFERS', index, 'ITEM_PRICES', 0)
      regular_price = source['BASE_PRICE']
      price = source['PRICE']
      if regular_price == price
        prepare_json['OFFERS'].map { |offer| offer['ITEM_PRICES'].first['BASE_PRICE'] }.max
      else
        regular_price
      end
    else
      prepare_json.dig('PRODUCT', 'ITEM_PRICES', 0, 'BASE_PRICE')
    end
  end

  def regular_price(index = nil, product = nil)
    price = multi_products.any? ? product.xpath('./@data-old-price').text.tr(',', '.').to_f : prepare_json.dig('PRODUCT', 'ITEM_PRICES', 0, 'BASE_PRICE').to_f
    price.positive? ? price : base_price(index)
  end
end
