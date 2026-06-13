import {
  Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { OffersService } from './offers.service';
import { CreateOfferDto } from './dto/create-offer.dto';
import { UpdateOfferDto } from './dto/update-offer.dto';
import { FilterOfferDto } from './dto/filter-offer.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';

@ApiTags('Offers')
@Controller('offers')
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  @Get()
  @ApiOperation({ summary: 'Lister les offres (recherche, filtres, pagination)' })
  findAll(@Query() filter: FilterOfferDto) {
    return this.offersService.findAll(filter);
  }

  @Get('mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mes offres (entreprise)' })
  myOffers(@CurrentUser() user: AuthUser, @Query() filter: FilterOfferDto) {
    return this.offersService.myOffers(user, filter);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail d’une offre' })
  findOne(@Param('id') id: string) {
    return this.offersService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une offre (entreprise)' })
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateOfferDto) {
    return this.offersService.create(user, dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY, Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Modifier une offre' })
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateOfferDto) {
    return this.offersService.update(user, id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY, Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Supprimer une offre' })
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.offersService.remove(user, id);
  }
}
