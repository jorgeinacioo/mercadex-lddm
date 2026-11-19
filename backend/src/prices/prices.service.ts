import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PriceObservationStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePriceDto } from './dto/create-price.dto';

@Injectable()
export class PricesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Records a price seen by a user. The new price becomes the active one for
   * that product at that branch; the previous active price is expired, so
   * the comparison never mixes an old and a new price for the same shelf.
   */
  async create(userId: string, input: CreatePriceDto) {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user || !user.isActive) {
        throw new UnauthorizedException();
      }

      // Locks the branch row so two reports for the same shelf run one after
      // the other; otherwise both could stay ACTIVE.
      const locked = await tx.$queryRaw<{ id: string }[]>`
        SELECT "id" FROM "MarketBranch" WHERE "id" = ${input.branchId} FOR UPDATE`;
      if (locked.length === 0) throw new NotFoundException('Branch not found');

      const product = await tx.product.findUnique({
        where: { id: input.productId },
      });
      if (!product) throw new NotFoundException('Product not found');
      const branch = { id: input.branchId };

      await tx.priceObservation.updateMany({
        where: {
          productId: product.id,
          branchId: branch.id,
          status: PriceObservationStatus.ACTIVE,
        },
        data: { status: PriceObservationStatus.EXPIRED },
      });

      const observation = await tx.priceObservation.create({
        data: {
          productId: product.id,
          branchId: branch.id,
          submittedById: user.id,
          price: input.price.toFixed(2),
          status: PriceObservationStatus.ACTIVE,
        },
        select: {
          id: true,
          price: true,
          observedAt: true,
          branch: {
            select: {
              id: true,
              name: true,
              address: true,
              market: { select: { id: true, name: true } },
            },
          },
        },
      });

      return {
        id: observation.id,
        price: observation.price.toFixed(2),
        observedAt: observation.observedAt,
        submittedBy: user.username,
        market: observation.branch.market,
        branch: {
          id: observation.branch.id,
          name: observation.branch.name,
          address: observation.branch.address,
        },
      };
    });
  }
}
