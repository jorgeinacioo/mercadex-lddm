import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, UserRole } from '@prisma/client';
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

type CatalogBranch = {
  id: string;
  name: string;
  unitLabel: string;
  address: string;
  latitude: number;
  longitude: number;
};

type CatalogMarket = {
  id: string;
  name: string;
  branches: CatalogBranch[];
};

type CatalogProduct = {
  id: string;
  name: string;
  brand: string;
  packaging: string;
  category: string;
  tags: string[];
  barcode: string;
  // Price per branch id, as a decimal string ("8.99").
  prices: Record<string, string>;
};

type Catalog = {
  markets: CatalogMarket[];
  products: CatalogProduct[];
};

// Development accounts only. Never reuse these credentials outside local demos.
const demoUsers = [
  { username: 'admin', password: 'admin', role: UserRole.ADMIN },
  { username: 'jorge', password: 'mercadex', role: UserRole.USER },
  { username: 'fernando', password: 'mercadex', role: UserRole.USER },
];

// Markets created by earlier seeds, replaced by the ids in catalog.json.
const legacyMarketIds = [
  'freshmart',
  'value-foods',
  'green-grocer',
  'daily-market',
];

async function main() {
  const catalog = JSON.parse(
    await readFile(join(__dirname, 'seed', 'catalog.json'), 'utf8'),
  ) as Catalog;

  await prisma.market.deleteMany({ where: { id: { in: legacyMarketIds } } });

  for (const market of catalog.markets) {
    await prisma.market.upsert({
      where: { id: market.id },
      update: { name: market.name },
      create: { id: market.id, name: market.name },
    });

    for (const branch of market.branches) {
      const data = {
        marketId: market.id,
        name: branch.name,
        unitLabel: branch.unitLabel,
        address: branch.address,
        latitude: branch.latitude,
        longitude: branch.longitude,
      };
      await prisma.marketBranch.upsert({
        where: { id: branch.id },
        update: data,
        create: { id: branch.id, ...data },
      });
    }
  }

  for (const { prices, ...product } of catalog.products) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: product,
      create: product,
    });

    for (const [branchId, price] of Object.entries(prices)) {
      const id = `seed-${product.id}-${branchId}`;
      // The status is set only on creation, so prices replaced by users stay
      // expired when the seed runs again.
      await prisma.priceObservation.upsert({
        where: { id },
        update: { price },
        create: {
          id,
          productId: product.id,
          branchId,
          price,
          status: 'ACTIVE',
        },
      });
    }
  }

  for (const user of demoUsers) {
    const passwordHash = await hash(user.password, 12);
    await prisma.user.upsert({
      where: { username: user.username },
      update: { passwordHash, role: user.role, isActive: true },
      create: {
        username: user.username,
        passwordHash,
        role: user.role,
      },
    });
  }

  console.log(
    `Seed: ${catalog.markets.length} markets, ${catalog.products.length} products, ${demoUsers.length} users.`,
  );
}

void main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
