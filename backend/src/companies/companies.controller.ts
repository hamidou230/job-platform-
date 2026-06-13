import {
  BadRequestException, Body, Controller, Get, Param, Patch, Post,
  Query, UploadedFile, UseGuards, UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { CompaniesService } from './companies.service';
import { UpdateCompanyDto } from './dto/update-company.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';

@ApiTags('Companies')
@Controller('companies')
export class CompaniesController {
  constructor(private readonly service: CompaniesService) {}

  @Get()
  @ApiOperation({ summary: 'Lister les entreprises' })
  findAll(@Query() pagination: PaginationDto) {
    return this.service.findAll(pagination);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mon profil entreprise' })
  getMe(@CurrentUser() user: AuthUser) {
    return this.service.getMe(user);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour mon profil entreprise' })
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdateCompanyDto) {
    return this.service.updateMe(user, dto);
  }

  @Post('me/logo')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.COMPANY)
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Téléverser le logo entreprise (JPG/PNG/WEBP, max 2 Mo)' })
  @ApiBody({
    schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads/logos',
        filename: (req, file, cb) => {
          const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `logo-${unique}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 2 * 1024 * 1024 },
      fileFilter: (req, file, cb) => {
        const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
        if (!allowed.includes(extname(file.originalname).toLowerCase())) {
          return cb(new BadRequestException('Format non supporté (JPG, PNG, WEBP).'), false);
        }
        cb(null, true);
      },
    }),
  )
  uploadLogo(@CurrentUser() user: AuthUser, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Aucun fichier reçu.');
    const logoUrl = `/uploads/logos/${file.filename}`;
    return this.service.setLogo(user, logoUrl);
  }

  @Get(':id')
  @ApiOperation({ summary: "Détail d'une entreprise" })
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }
}
