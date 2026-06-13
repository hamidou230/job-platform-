import {
  BadRequestException, ForbiddenException, Injectable, NotFoundException,
} from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateApplicationDto } from './dto/create-application.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { PaginationDto, buildPaginatedResult } from '../common/dto/pagination.dto';
import { AuthUser } from '../common/decorators/current-user.decorator';

@Injectable()
export class ApplicationsService {
  constructor(private prisma: PrismaService) {}

  private async getStudent(userId: string) {
    const student = await this.prisma.student.findUnique({ where: { userId } });
    if (!student) throw new ForbiddenException('Profil étudiant introuvable.');
    return student;
  }

  async apply(user: AuthUser, dto: CreateApplicationDto) {
    const student = await this.getStudent(user.userId);

    const offer = await this.prisma.offer.findUnique({
      where: { id: dto.offerId },
      include: { company: true },
    });
    if (!offer) throw new NotFoundException('Offre introuvable.');
    if (offer.status !== 'OPEN') throw new BadRequestException('Cette offre n’accepte plus de candidatures.');

    const already = await this.prisma.application.findUnique({
      where: { studentId_offerId: { studentId: student.id, offerId: dto.offerId } },
    });
    if (already) throw new BadRequestException('Vous avez déjà postulé à cette offre.');

    const application = await this.prisma.application.create({
      data: {
        studentId: student.id,
        offerId: dto.offerId,
        coverLetter: dto.coverLetter,
        cvUrl: dto.cvUrl ?? student.cvUrl,
      },
      include: { offer: { include: { company: true } } },
    });

    // Notifier l'entreprise
    await this.prisma.notification.create({
      data: {
        userId: offer.company.userId,
        title: 'Nouvelle candidature',
        message: `${student.firstName} ${student.lastName} a postulé à "${offer.title}".`,
        type: NotificationType.APPLICATION,
      },
    });

    return application;
  }

  // Candidatures de l'étudiant connecté
  async myApplications(user: AuthUser, pagination: PaginationDto) {
    const student = await this.getStudent(user.userId);
    const where = { studentId: student.id };

    const [data, total] = await this.prisma.$transaction([
      this.prisma.application.findMany({
        where,
        skip: pagination.skip,
        take: pagination.limit,
        orderBy: { createdAt: 'desc' },
        include: {
          offer: { include: { company: { select: { name: true, logoUrl: true } } } },
        },
      }),
      this.prisma.application.count({ where }),
    ]);
    return buildPaginatedResult(data, total, pagination.page, pagination.limit);
  }

  // Candidatures reçues sur une offre de l'entreprise
  async applicationsForOffer(user: AuthUser, offerId: string, pagination: PaginationDto) {
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: { company: true },
    });
    if (!offer) throw new NotFoundException('Offre introuvable.');
    if (user.role !== 'ADMIN' && offer.company.userId !== user.userId) {
      throw new ForbiddenException('Accès refusé.');
    }

    const where = { offerId };
    const [data, total] = await this.prisma.$transaction([
      this.prisma.application.findMany({
        where,
        skip: pagination.skip,
        take: pagination.limit,
        orderBy: { createdAt: 'desc' },
        include: { student: true },
      }),
      this.prisma.application.count({ where }),
    ]);
    return buildPaginatedResult(data, total, pagination.page, pagination.limit);
  }

  async updateStatus(user: AuthUser, id: string, dto: UpdateStatusDto) {
    const application = await this.prisma.application.findUnique({
      where: { id },
      include: { offer: { include: { company: true } }, student: true },
    });
    if (!application) throw new NotFoundException('Candidature introuvable.');
    if (user.role !== 'ADMIN' && application.offer.company.userId !== user.userId) {
      throw new ForbiddenException('Accès refusé.');
    }

    const updated = await this.prisma.application.update({
      where: { id },
      data: { status: dto.status },
    });

    const label = { ACCEPTED: 'acceptée', REJECTED: 'refusée', REVIEWED: 'examinée', PENDING: 'en attente' }[dto.status];
    await this.prisma.notification.create({
      data: {
        userId: application.student.userId,
        title: 'Mise à jour de candidature',
        message: `Votre candidature pour "${application.offer.title}" a été ${label}.`,
        type: NotificationType.APPLICATION,
      },
    });

    return updated;
  }

  async withdraw(user: AuthUser, id: string) {
    const student = await this.getStudent(user.userId);
    const application = await this.prisma.application.findUnique({ where: { id } });
    if (!application) throw new NotFoundException('Candidature introuvable.');
    if (application.studentId !== student.id) throw new ForbiddenException('Accès refusé.');
    await this.prisma.application.delete({ where: { id } });
    return { message: 'Candidature retirée.' };
  }
}
