import { BadRequestException, Injectable } from '@nestjs/common';
import { normalizeText } from '../products/product-summary';
import { ProductsService } from '../products/products.service';

@Injectable()
export class SearchService {
  constructor(private readonly products: ProductsService) {}

  // The catalog is small, so matching runs in memory. This keeps accent- and
  // case-insensitive search simple without a PostgreSQL extension.
  async search(query: string | undefined) {
    const terms = normalizeText(query ?? '')
      .split(/\s+/)
      .filter(Boolean);
    if (terms.length === 0) {
      throw new BadRequestException('Query is required');
    }

    const products = await this.products.findAll();
    return products.filter((product) => {
      const text = normalizeText(
        [
          product.name,
          product.brand,
          product.category,
          product.barcode ?? '',
          ...product.tags,
        ].join(' '),
      );
      return terms.every((term) => text.includes(term));
    });
  }
}
