import { Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { AdminService } from './admin.service';
import { PaginationDto } from '../common/dto/pagination.dto';
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
  @ApiOperation({ summary: 'Lister les utilisateurs' })
  users(@Query() pagination: PaginationDto) {
    return this.service.listUsers(pagination);
  }

  @Patch('users/:id/toggle-active')
  @ApiOperation({ summary: 'Activer/désactiver un compte' })
  toggle(@Param('id') id: string) {
    return this.service.toggleUserActive(id);
  }
}
