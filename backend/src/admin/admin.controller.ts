import { Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { AdminService } from './admin.service';
import { PaginationDto } from '../common/dto/pagination.dto';
import { AdminUsersFilterDto } from './dto/admin-users-filter.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly service: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Statistiques du tableau de bord' })
  stats() {
    return this.service.stats();
  }

  @Get('users')
  @ApiOperation({ summary: 'Lister les utilisateurs (filtre role optionnel)' })
  users(@Query() filter: AdminUsersFilterDto) {
    return this.service.listUsers(filter, filter.role);
  }

  @Get('applications')
  @ApiOperation({ summary: 'Toutes les candidatures' })
  applications(@Query() pagination: PaginationDto) {
    return this.service.listApplications(pagination);
  }

  @Patch('users/:id/toggle-active')
  @ApiOperation({ summary: 'Activer/désactiver un compte' })
  toggle(@Param('id') id: string) {
    return this.service.toggleUserActive(id);
  }
}
