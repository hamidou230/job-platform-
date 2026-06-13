import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const exists = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (exists) throw new ConflictException('Un compte existe déjà avec cet email.');

    const hash = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        password: hash,
        role: dto.role,
        // Création du profil lié selon le rôle
        ...(dto.role === Role.STUDENT && {
          student: {
            create: {
              firstName: dto.firstName ?? 'Prénom',
              lastName: dto.lastName ?? 'Nom',
            },
          },
        }),
        ...(dto.role === Role.COMPANY && {
          company: {
            create: { name: dto.companyName ?? 'Entreprise' },
          },
        }),
      },
      include: { student: true, company: true },
    });

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { student: true, company: true },
    });
    if (!user) throw new UnauthorizedException('Email ou mot de passe incorrect.');

    const valid = await bcrypt.compare(dto.password, user.password);
    if (!valid) throw new UnauthorizedException('Email ou mot de passe incorrect.');
    if (!user.isActive) throw new UnauthorizedException('Compte désactivé.');

    return this.buildAuthResponse(user);
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { student: true, company: true },
    });
    if (!user) throw new UnauthorizedException();
    return this.sanitize(user);
  }

  private buildAuthResponse(user: any) {
    const token = this.jwt.sign(
      { sub: user.id, email: user.email, role: user.role },
      {
        secret: this.config.get('JWT_SECRET'),
        expiresIn: this.config.get('JWT_EXPIRES_IN') || '7d',
      },
    );
    return { accessToken: token, user: this.sanitize(user) };
  }

  private sanitize(user: any) {
    const { password, ...rest } = user;
    return rest;
  }
}
