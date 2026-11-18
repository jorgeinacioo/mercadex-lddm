import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { compare } from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async login({ username, password }: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { username: username.trim().toLowerCase() },
    });

    if (
      !user ||
      !user.isActive ||
      !(await compare(password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Invalid username or password');
    }

    return {
      accessToken: await this.jwt.signAsync({ role: user.role, sub: user.id }),
      user: { username: user.username, role: user.role },
    };
  }
}
