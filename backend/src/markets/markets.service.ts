import { Injectable, NotFoundException } from '@nestjs/common';
import { activePrices } from '../products/product-summary';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MarketsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    const markets = await this.prisma.market.findMany({
      select: {
        id: true,
        name: true,
        branches: {
          select: {
            priceObservations: {
              where: activePrices,
              select: { productId: true },
            },
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    return markets.map((market) => ({
      id: market.id,
      name: market.name,
      branchCount: market.branches.length,
      productCount: new Set(
        market.branches.flatMap((branch) =>
          branch.priceObservations.map((observation) => observation.productId),
        ),
      ).size,
    }));
  }

  async findOne(marketId: string) {
    const market = await this.prisma.market.findUnique({
      where: { id: marketId },
      select: {
        id: true,
        name: true,
        branches: {
          select: {
            id: true,
            name: true,
            address: true,
            latitude: true,
            longitude: true,
          },
          orderBy: { name: 'asc' },
        },
      },
    });

    if (!market) {
      throw new NotFoundException('Market not found');
    }

    const observations = await this.prisma.priceObservation.findMany({
      where: { ...activePrices, branch: { marketId } },
      select: {
        price: true,
        product: {
          select: { id: true, name: true, packaging: true, category: true },
        },
      },
      orderBy: { price: 'asc' },
    });

    // Lowest active price of each product across the market's branches.
    const products = new Map<
      string,
      (typeof observations)[number]['product'] & { price: string }
    >();
    for (const observation of observations) {
      if (products.has(observation.product.id)) continue;
      products.set(observation.product.id, {
        ...observation.product,
        price: observation.price.toFixed(2),
      });
    }

    return {
      ...market,
      branches: market.branches.map((branch) => ({
        ...branch,
        latitude: Number(branch.latitude),
        longitude: Number(branch.longitude),
      })),
      products: [...products.values()].sort((a, b) =>
        a.name.localeCompare(b.name, 'pt-BR'),
      ),
    };
  }
}
