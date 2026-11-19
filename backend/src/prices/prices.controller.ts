import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedRequest } from '../auth/jwt-auth.guard';
import { CreatePriceDto } from './dto/create-price.dto';
import { PricesService } from './prices.service';

@UseGuards(JwtAuthGuard)
@Controller('prices')
export class PricesController {
  constructor(private readonly pricesService: PricesService) {}

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() body: CreatePriceDto) {
    // The author always comes from the token, never from the request body.
    return this.pricesService.create(request.user.sub, body);
  }
}
