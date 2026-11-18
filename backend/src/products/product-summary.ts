import { Prisma, PriceObservationStatus } from '@prisma/client';

export const activePrices = { status: PriceObservationStatus.ACTIVE };

export const productSummarySelect = {
  id: true,
  name: true,
  brand: true,
  packaging: true,
  category: true,
  tags: true,
  barcode: true,
  priceObservations: {
    where: activePrices,
    select: {
      price: true,
      branch: { select: { market: { select: { id: true, name: true } } } },
    },
  },
} satisfies Prisma.ProductSelect;

export type ProductSummaryRow = Prisma.ProductGetPayload<{
  select: typeof productSummarySelect;
}>;

export function toProductSummary(product: ProductSummaryRow) {
  const cheapest = product.priceObservations.reduce<
    ProductSummaryRow['priceObservations'][number] | null
  >(
    (best, observation) =>
      best == null || observation.price.lessThan(best.price)
        ? observation
        : best,
    null,
  );
  const highest = product.priceObservations.reduce<
    ProductSummaryRow['priceObservations'][number] | null
  >(
    (best, observation) =>
      best == null || observation.price.greaterThan(best.price)
        ? observation
        : best,
    null,
  );
  const marketIds = new Set(
    product.priceObservations.map(
      (observation) => observation.branch.market.id,
    ),
  );

  return {
    id: product.id,
    name: product.name,
    brand: product.brand,
    packaging: product.packaging,
    category: product.category,
    tags: product.tags,
    barcode: product.barcode,
    lowestPrice: cheapest?.price.toFixed(2) ?? null,
    lowestPriceMarket: cheapest?.branch.market ?? null,
    highestPrice: highest?.price.toFixed(2) ?? null,
    marketCount: marketIds.size,
  };
}

/** Lowercase and strip accents, so "cafe" matches "Café". */
export function normalizeText(value: string) {
  return value
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase()
    .trim();
}
