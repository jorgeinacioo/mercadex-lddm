import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { MarketsModule } from './markets/markets.module';
import { ProductsModule } from './products/products.module';
import { SearchModule } from './search/search.module';

@Module({
  imports: [
    AuthModule,
    MarketsModule,
    ProductsModule,
    SearchModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
