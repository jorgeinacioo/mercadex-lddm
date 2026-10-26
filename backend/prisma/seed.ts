import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { hash } from 'bcryptjs';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

type ProductSeed = {
  id: string;
  name: string;
  brand: string;
  packaging: string;
  category: string;
  tags: string[];
};

const marketSeeds = [
  {
    id: 'freshmart',
    name: 'Carrefour',
    branch: {
      id: 'freshmart-central',
      name: 'Carrefour Central',
      unitLabel: 'Central',
      address: '100 Market Street',
      latitude: -23.55052,
      longitude: -46.633308,
    },
  },
  {
    id: 'value-foods',
    name: 'Pão de Açúcar',
    branch: {
      id: 'value-foods-central',
      name: 'Pão de Açúcar Central',
      unitLabel: 'Central',
      address: '200 Market Street',
      latitude: -23.55252,
      longitude: -46.635308,
    },
  },
  {
    id: 'green-grocer',
    name: 'Assaí Atacadista',
    branch: {
      id: 'green-grocer-central',
      name: 'Assaí Atacadista Central',
      unitLabel: 'Central',
      address: '300 Market Street',
      latitude: -23.55452,
      longitude: -46.637308,
    },
  },
  {
    id: 'daily-market',
    name: 'Atacadão',
    branch: {
      id: 'daily-market-central',
      name: 'Atacadão Central',
      unitLabel: 'Central',
      address: '400 Market Street',
      latitude: -23.55652,
      longitude: -46.639308,
    },
  },
];

const basePriceByProductId: Record<string, number> = {
  'coke-2l': 8.99,
  'agua-1-5l': 3.49,
  'cafe-500g': 18.99,
  'leite-1l': 5.49,
  'iogurte-natural-170g': 3.29,
  'manteiga-200g': 12.99,
  'mussarela-200g': 14.99,
  'arroz-5kg': 29.99,
  'feijao-1kg': 8.49,
  'macarrao-500g': 5.99,
  'farinha-trigo-1kg': 6.29,
  'aveia-170g': 8.99,
  'acucar-1kg': 4.99,
  'sal-1kg': 2.49,
  'oleo-soja-900ml': 8.99,
  'molho-tomate-300g': 3.49,
  'milho-lata-170g': 4.29,
  'ervilha-lata-170g': 4.29,
  'atum-lata-170g': 9.99,
  'sardinha-lata-125g': 6.99,
  'banana-prata-1kg': 3.99,
  'banana-nanica-1kg': 4.29,
  'banana-organica-1kg': 5.99,
  'maca-gala-1kg': 10.99,
  'laranja-pera-1kg': 5.99,
  'tomate-1kg': 8.99,
  'batata-1kg': 5.49,
  'cebola-1kg': 4.99,
  'cenoura-1kg': 5.99,
  'alface-un': 3.99,
  'pao-forma-500g': 9.99,
  'ovos-12un': 12.99,
  'peito-frango-1kg': 18.99,
  'carne-moida-1kg': 34.99,
};

const priceObservationSeeds = [
  {
    id: 'banana-prata-freshmart',
    productId: 'banana-prata-1kg',
    branchId: 'freshmart-central',
    price: 3.99,
    status: 'ACTIVE' as const,
    observedAt: new Date('2026-09-25T10:00:00Z'),
  },
  {
    id: 'banana-nanica-value-foods',
    productId: 'banana-nanica-1kg',
    branchId: 'value-foods-central',
    price: 4.29,
    status: 'ACTIVE' as const,
    observedAt: new Date('2026-09-26T10:00:00Z'),
  },
  {
    id: 'banana-prata-value-foods',
    productId: 'banana-prata-1kg',
    branchId: 'value-foods-central',
    price: 4.19,
    status: 'ACTIVE' as const,
    observedAt: new Date('2026-09-26T12:00:00Z'),
  },
  {
    id: 'banana-prata-daily-market',
    productId: 'banana-prata-1kg',
    branchId: 'daily-market-central',
    price: 4.49,
    status: 'ACTIVE' as const,
    observedAt: new Date('2026-09-27T09:00:00Z'),
  },
  {
    id: 'banana-organica-green-grocer',
    productId: 'banana-organica-1kg',
    branchId: 'green-grocer-central',
    price: 5.99,
    status: 'ACTIVE' as const,
    observedAt: new Date('2026-09-27T10:00:00Z'),
  },
];

async function main() {
  const products: ProductSeed[] = JSON.parse(
    await readFile(join(__dirname, 'seed', 'products.json'), 'utf8'),
  );

  for (const product of products) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: product,
      create: product,
    });
  }

  for (const market of marketSeeds) {
    await prisma.market.upsert({
      where: { id: market.id },
      update: { name: market.name },
      create: { id: market.id, name: market.name },
    });

    await prisma.marketBranch.upsert({
      where: { id: market.branch.id },
      update: {
        marketId: market.id,
        name: market.branch.name,
        unitLabel: market.branch.unitLabel,
        address: market.branch.address,
        latitude: market.branch.latitude,
        longitude: market.branch.longitude,
      },
      create: {
        id: market.branch.id,
        marketId: market.id,
        name: market.branch.name,
        unitLabel: market.branch.unitLabel,
        address: market.branch.address,
        latitude: market.branch.latitude,
        longitude: market.branch.longitude,
      },
    });
  }

  const branchIds = marketSeeds.map((market) => market.branch.id);
  for (const [index, product] of products.entries()) {
    const price = basePriceByProductId[product.id];
    if (price == null) {
      throw new Error(`Missing base price for ${product.id}`);
    }

    await prisma.priceObservation.upsert({
      where: { id: `${product.id}-base-price` },
      update: {
        productId: product.id,
        branchId: branchIds[index % branchIds.length],
        price,
        status: 'ACTIVE',
      },
      create: {
        id: `${product.id}-base-price`,
        productId: product.id,
        branchId: branchIds[index % branchIds.length],
        price,
        status: 'ACTIVE',
      },
    });
  }

  for (const observation of priceObservationSeeds) {
    await prisma.priceObservation.upsert({
      where: { id: observation.id },
      update: {
        productId: observation.productId,
        branchId: observation.branchId,
        price: observation.price,
        status: observation.status,
        observedAt: observation.observedAt,
      },
      create: observation,
    });
  }

  const passwordHash = await hash('admin', 12);

  await prisma.user.upsert({
    where: { username: 'admin' },
    update: { passwordHash, role: 'ADMIN', isActive: true },
    create: {
      username: 'admin',
      passwordHash,
      role: 'ADMIN',
    },
  });
}

void main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
