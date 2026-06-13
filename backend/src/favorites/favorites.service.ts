import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaginationDto, buildPaginatedResult } from '../common/dto/pagination.dto';
import { AuthUser } from '../common/decorators/current-user.decorator';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  private async getStudent(userId: string) {
    const student = await this.prisma.student.findUnique({ where: { userId } });
    if (!student) throw new ForbiddenException('Profil étudiant introuvable.');
    return student;
  }

  async toggle(user: AuthUser, offerId: string) {
    const student = await this.getStudent(user.userId);
    const offer = await this.prisma.offer.findUnique({ where: { id: offerId } });
    if (!offer) throw new NotFoundException('Offre introuvable.');

    const existing = await this.prisma.favorite.findUnique({
      where: { studentId_offerId: { studentId: student.id, offerId } },
    });

    if (existing) {
      await this.prisma.favorite.delete({ where: { id: existing.id } });
      return { favorited: false };
    }
    await this.prisma.favorite.create({ data: { studentId: student.id, offerId } });
    return { favorited: true };
  }

  async list(user: AuthUser, pagination: PaginationDto) {
    const student = await this.getStudent(user.userId);
    const where = { studentId: student.id };
    const [data, total] = await this.prisma.$transaction([
      this.prisma.favorite.findMany({
        where,
        skip: pagination.skip,
        take: pagination.limit,
        orderBy: { createdAt: 'desc' },
        include: {
          offer: { include: { company: { select: { name: true, logoUrl: true } } } },
        },
      }),
      this.prisma.favorite.count({ where }),
    ]);
    return buildPaginatedResult(data, total, pagination.page, pagination.limit);
  }
}
