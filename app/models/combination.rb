class Combination < ActiveRecord::Base
  belongs_to :wardrobe

  validates_uniqueness_of :products, :scope => [:wardrobe_id]

  def product_name
    names = []
    for id in self.products.split(",")
      p = Product.find_by_id(id)
      if p
        names << p.name
      end
    end
    return(names * " + ")
  end

  def product
    prod = nil
    for id in self.products.split(",")
      prod = Product.find_by_id(id)
#      break;
    end
    return prod
  end
end
