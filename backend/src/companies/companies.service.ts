import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateCompanyDto } from './dto/update-company.dto';
import { PaginationDto, buildPaginatedResult } from '../common/dto/pagination.dto';
import { AuthUser } from '../common/decorators/current-user.decorator';

@Injectable()
export class CompaniesService {
  constructor(private prisma: PrismaService) {}

  async getMe(user: AuthUser) {
    const company = await this.prisma.company.findUnique({
      where: { userId: user.userId },
      include: { _count: { select: { offers: true } } },
    });
    if (!company) throw new NotFoundException('Profil entreprise introuvable.');
    return company;
  }

  async updateMe(user: AuthUser, dto: UpdateCompanyDto) {
    return this.prisma.company.update({ where: { userId: user.userId }, data: dto });
  }

  async setLogo(user: AuthUser, logoUrl: string) {
    return this.prisma.company.update({
      where: { userId: user.userId },
      data: { logoUrl },
      select: { id: true, logoUrl: true },
    });
  }

  async findAll(pagination: PaginationDto) {
    const where = pagination.search
      ? { name: { contains: pagination.search } }
      : {};
    const [data, total] = await this.prisma.$transaction([
      this.prisma.company.findMany({
        where,
        skip: pagination.skip,
        take: pagination.limit,
        orderBy: { createdAt: 'desc' },
        include: { _count: { select: { offers: true } } },
      }),
      this.prisma.company.count({ where }),
    ]);
    return buildPaginatedResult(data, total, pagination.page, pagination.limit);
  }

  async findOne(id: string) {
    const company = await this.prisma.company.findUnique({
      where: { id },
      include: {
        offers: { where: { status: 'OPEN' }, orderBy: { createdAt: 'desc' }, take: 20 },
      },
    });
    if (!company) throw new NotFoundException('Entreprise introuvable.');
    return company;
  }
}
