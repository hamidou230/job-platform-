import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateStudentDto } from './dto/update-student.dto';
import { AuthUser } from '../common/decorators/current-user.decorator';

@Injectable()
export class StudentsService {
  constructor(private prisma: PrismaService) {}

  async getMe(user: AuthUser) {
    const student = await this.prisma.student.findUnique({
      where: { userId: user.userId },
      include: {
        user: { select: { email: true, role: true } },
        _count: { select: { applications: true, favorites: true } },
      },
    });
    if (!student) throw new NotFoundException('Profil étudiant introuvable.');
    return student;
  }

  async updateMe(user: AuthUser, dto: UpdateStudentDto) {
    return this.prisma.student.update({ where: { userId: user.userId }, data: dto });
  }

  async setCv(user: AuthUser, cvUrl: string) {
    return this.prisma.student.update({
      where: { userId: user.userId },
      data: { cvUrl },
      select: { id: true, cvUrl: true },
    });
  }

  async setAvatar(user: AuthUser, avatarUrl: string) {
    return this.prisma.student.update({
      where: { userId: user.userId },
      data: { avatarUrl },
      select: { id: true, avatarUrl: true },
    });
  }

  async findOne(id: string) {
    const student = await this.prisma.student.findUnique({ where: { id } });
    if (!student) throw new NotFoundException('Étudiant introuvable.');
    return student;
  }
}
