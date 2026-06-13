import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { FavoritesService } from './favorites.service';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';

@ApiTags('Favorites')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.STUDENT)
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly service: FavoritesService) {}

  @Post(':offerId/toggle')
  @ApiOperation({ summary: 'Ajouter/retirer une offre des favoris' })
  toggle(@CurrentUser() user: AuthUser, @Param('offerId') offerId: string) {
    return this.service.toggle(user, offerId);
  }

  @Get()
  @ApiOperation({ summary: 'Mes offres favorites' })
  list(@CurrentUser() user: AuthUser, @Query() pagination: PaginationDto) {
    return this.service.list(user, pagination);
  }
}
