import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  activePrices,
  productSummarySelect,
  toProductSummary,
} from './product-summary';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Products that currently have at least one active price. */
  async findAll() {
    const products = await this.prisma.product.findMany({
      where: { priceObservations: { some: activePrices } },
      select: productSummarySelect,
      orderBy: { name: 'asc' },
    });
    return products.map(toProductSummary);
  }

  async findByBarcode(barcode: string) {
    const product = await this.prisma.product.findFirst({
      where: {
        barcode: barcode.trim(),
        priceObservations: { some: activePrices },
      },
      select: productSummarySelect,
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    return toProductSummary(product);
  }

  async findDeals(productId: string) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, priceObservations: { some: activePrices } },
      select: {
        id: true,
        name: true,
        brand: true,
        packaging: true,
        category: true,
        barcode: true,
        priceObservations: {
          where: activePrices,
          select: {
            id: true,
            price: true,
            observedAt: true,
            submittedBy: { select: { username: true } },
            branch: {
              select: {
                id: true,
                name: true,
                address: true,
                market: { select: { id: true, name: true } },
              },
            },
          },
          orderBy: [{ price: 'asc' }, { observedAt: 'desc' }],
        },
      },
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    const { priceObservations, ...details } = product;
    return {
      ...details,
      deals: priceObservations.map((observation) => ({
        id: observation.id,
        price: observation.price.toFixed(2),
        observedAt: observation.observedAt,
        submittedBy: observation.submittedBy?.username ?? null,
        market: observation.branch.market,
        branch: {
          id: observation.branch.id,
          name: observation.branch.name,
          address: observation.branch.address,
        },
      })),
    };
  }
}
