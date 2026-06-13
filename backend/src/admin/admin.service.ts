import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaginationDto, buildPaginatedResult } from '../common/dto/pagination.dto';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async stats() {
    const [users, students, companies, offers, applications, openOffers] =
      await this.prisma.$transaction([
        this.prisma.user.count(),
        this.prisma.student.count(),
        this.prisma.company.count(),
        this.prisma.offer.count(),
        this.prisma.application.count(),
        this.prisma.offer.count({ where: { status: 'OPEN' } }),
      ]);

    const applicationsByStatus = await this.prisma.application.groupBy({
      by: ['status'],
      _count: true,
    });
    const offersByType = await this.prisma.offer.groupBy({
      by: ['type'],
      _count: true,
    });

    return {
      totals: { users, students, companies, offers, openOffers, applications },
      applicationsByStatus,
      offersByType,
    };
  }

  async listUsers(pagination: PaginationDto) {
    const where = pagination.search ? { email: { contains: pagination.search } } : {};
    const [data, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        skip: pagination.skip,
        take: pagination.limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true, email: true, role: true, isActive: true, createdAt: true,
          student: { select: { firstName: true, lastName: true } },
          company: { select: { name: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return buildPaginatedResult(data, total, pagination.page, pagination.limit);
  }

  async toggleUserActive(id: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id } });
    return this.prisma.user.update({
      where: { id },
      data: { isActive: !user.isActive },
      select: { id: true, isActive: true },
    });
  }
}
