import {
  Body, Controller, Get, Param, Patch, Post, UploadedFile, UseGuards, UseInterceptors,
  BadRequestException, Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import {
  ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { StudentsService } from './students.service';
import { UpdateStudentDto } from './dto/update-student.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';

@ApiTags('Students')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('students')
export class StudentsController {
  constructor(private readonly service: StudentsService) {}

  @Get('me')
  @Roles(Role.STUDENT)
  @ApiOperation({ summary: 'Mon profil étudiant' })
  getMe(@CurrentUser() user: AuthUser) {
    return this.service.getMe(user);
  }

  @Patch('me')
  @Roles(Role.STUDENT)
  @ApiOperation({ summary: 'Mettre à jour mon profil' })
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdateStudentDto) {
    return this.service.updateMe(user, dto);
  }

  @Post('me/cv')
  @Roles(Role.STUDENT)
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Téléverser mon CV (PDF/DOC, max 5 Mo)' })
  @ApiBody({
    schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads/cv',
        filename: (req, file, cb) => {
          const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `cv-${unique}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (req, file, cb) => {
        const allowed = ['.pdf', '.doc', '.docx'];
        if (!allowed.includes(extname(file.originalname).toLowerCase())) {
          return cb(new BadRequestException('Format non supporté (PDF, DOC, DOCX).'), false);
        }
        cb(null, true);
      },
    }),
  )
  uploadCv(@CurrentUser() user: AuthUser, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Aucun fichier reçu.');
    const cvUrl = `/uploads/cv/${file.filename}`;
    return this.service.setCv(user, cvUrl);
  }

  @Post('me/avatar')
  @Roles(Role.STUDENT)
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Téléverser ma photo de profil (JPG/PNG/WEBP, max 2 Mo)' })
  @ApiBody({
    schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads/avatars',
        filename: (req, file, cb) => {
          const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `avatar-${unique}${extname(file.originalname)}`);
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
  uploadAvatar(@CurrentUser() user: AuthUser, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Aucun fichier reçu.');
    const avatarUrl = `/uploads/avatars/${file.filename}`;
    return this.service.setAvatar(user, avatarUrl);
  }

  @Get(':id')
  @Roles(Role.COMPANY, Role.ADMIN)
  @ApiOperation({ summary: "Profil public d'un étudiant" })
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }
}
