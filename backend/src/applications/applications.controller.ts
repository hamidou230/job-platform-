import {
  Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { ApplicationsService } from './applications.service';
import { CreateApplicationDto } from './dto/create-application.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';

@ApiTags('Applications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('applications')
export class ApplicationsController {
  constructor(private readonly service: ApplicationsService) {}

  @Post()
  @Roles(Role.STUDENT)
  @ApiOperation({ summary: 'Postuler à une offre (étudiant)' })
  apply(@CurrentUser() user: AuthUser, @Body() dto: CreateApplicationDto) {
    return this.service.apply(user, dto);
  }

  @Get('mine')
  @Roles(Role.STUDENT)
  @ApiOperation({ summary: 'Mes candidatures (étudiant)' })
  mine(@CurrentUser() user: AuthUser, @Query() pagination: PaginationDto) {
    return this.service.myApplications(user, pagination);
  }

  @Get('offer/:offerId')
  @Roles(Role.COMPANY, Role.ADMIN)
  @ApiOperation({ summary: 'Candidatures reçues pour une offre (entreprise)' })
  forOffer(
    @CurrentUser() user: AuthUser,
    @Param('offerId') offerId: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.service.applicationsForOffer(user, offerId, pagination);
  }

  @Patch(':id/status')
  @Roles(Role.COMPANY, Role.ADMIN)
  @ApiOperation({ summary: 'Changer le statut d’une candidature' })
  updateStatus(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateStatusDto) {
    return this.service.updateStatus(user, id, dto);
  }

  @Delete(':id')
  @Roles(Role.STUDENT)
  @ApiOperation({ summary: 'Retirer une candidature (étudiant)' })
  withdraw(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.service.withdraw(user, id);
  }
}
