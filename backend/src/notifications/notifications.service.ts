import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaginationDto, buildPaginatedResult } from '../common/dto/pagination.dto';
import { AuthUser } from '../common/decorators/current-user.decorator';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async list(user: AuthUser, pagination: PaginationDto) {
    const where = { userId: user.userId };
    const [data, total, unread] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where,
        skip: pagination.skip,
        take: pagination.limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({ where: { userId: user.userId, isRead: false } }),
    ]);
    const result = buildPaginatedResult(data, total, pagination.page, pagination.limit);
    return { ...result, unreadCount: unread };
  }

  async markRead(user: AuthUser, id: string) {
    const notif = await this.prisma.notification.findUnique({ where: { id } });
    if (!notif) throw new NotFoundException('Notification introuvable.');
    if (notif.userId !== user.userId) throw new ForbiddenException();
    return this.prisma.notification.update({ where: { id }, data: { isRead: true } });
  }

  async markAllRead(user: AuthUser) {
    await this.prisma.notification.updateMany({
      where: { userId: user.userId, isRead: false },
      data: { isRead: true },
    });
    return { message: 'Toutes les notifications sont lues.' };
  }
}
