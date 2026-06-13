import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOfferDto } from './dto/create-offer.dto';
import { UpdateOfferDto } from './dto/update-offer.dto';
import { FilterOfferDto } from './dto/filter-offer.dto';
import { buildPaginatedResult } from '../common/dto/pagination.dto';
import { AuthUser } from '../common/decorators/current-user.decorator';

@Injectable()
export class OffersService {
  constructor(private prisma: PrismaService) {}

  // Récupère l'entreprise liée à l'utilisateur connecté
  private async getCompanyOrThrow(userId: string) {
    const company = await this.prisma.company.findUnique({ where: { userId } });
    if (!company) throw new ForbiddenException('Profil entreprise introuvable.');
    return company;
  }

  async create(user: AuthUser, dto: CreateOfferDto) {
    const company = await this.getCompanyOrThrow(user.userId);
    return this.prisma.offer.create({
      data: { ...dto, companyId: company.id },
      include: { company: true },
    });
  }

  // Liste publique avec recherche + filtres + pagination
  async findAll(filter: FilterOfferDto) {
    const where: Prisma.OfferWhereInput = {};

    if (filter.status) where.status = filter.status;
    if (filter.type) where.type = filter.type;
    if (filter.experienceLevel) where.experienceLevel = filter.experienceLevel;
    if (filter.isRemote !== undefined) where.isRemote = filter.isRemote;
    if (filter.companyId) where.companyId = filter.companyId;

    if (filter.location) {
      where.location = { contains: filter.location };
    }
    if (filter.salaryMin) {
      where.salaryMax = { gte: filter.salaryMin };
    }

    // Recherche plein texte simple (titre + description)
    if (filter.search) {
      where.OR = [
        { title: { contains: filter.search } },
        { description: { contains: filter.search } },
      ];
    }

    // Filtre par compétences (chaque compétence doit apparaître)
    if (filter.skills) {
      const skills = filter.skills.split(',').map((s) => s.trim()).filter(Boolean);
      where.AND = skills.map((skill) => ({
        requiredSkills: { contains: skill },
      }));
    }

    const [data, total] = await this.prisma.$transaction([
      this.prisma.offer.findMany({
        where,
        skip: filter.skip,
        take: filter.limit,
        orderBy: { [filter.sortBy]: filter.order },
        include: {
          company: { select: { id: true, name: true, logoUrl: true, location: true } },
          _count: { select: { applications: true } },
        },
      }),
      this.prisma.offer.count({ where }),
    ]);

    return buildPaginatedResult(data, total, filter.page, filter.limit);
  }

  async findOne(id: string) {
    const offer = await this.prisma.offer.findUnique({
      where: { id },
      include: {
        company: true,
        _count: { select: { applications: true, favorites: true } },
      },
    });
    if (!offer) throw new NotFoundException('Offre introuvable.');
    return offer;
  }

  async update(user: AuthUser, id: string, dto: UpdateOfferDto) {
    await this.ensureOwner(user, id);
    return this.prisma.offer.update({ where: { id }, data: dto, include: { company: true } });
  }

  async remove(user: AuthUser, id: string) {
    await this.ensureOwner(user, id);
    await this.prisma.offer.delete({ where: { id } });
    return { message: 'Offre supprimée.' };
  }

  // Offres publiées par l'entreprise connectée
  async myOffers(user: AuthUser, filter: FilterOfferDto) {
    const company = await this.getCompanyOrThrow(user.userId);
    return this.findAll(Object.assign(filter, { companyId: company.id, status: filter.status }));
  }

  private async ensureOwner(user: AuthUser, offerId: string) {
    const offer = await this.prisma.offer.findUnique({
      where: { id: offerId },
      include: { company: true },
    });
    if (!offer) throw new NotFoundException('Offre introuvable.');
    if (user.role !== 'ADMIN' && offer.company.userId !== user.userId) {
      throw new ForbiddenException('Vous ne pouvez modifier que vos propres offres.');
    }
    return offer;
  }
}
