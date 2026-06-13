import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';
import { Role } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';

export class AdminUsersFilterDto extends PaginationDto {
  @ApiPropertyOptional({ enum: Role, description: 'Filtrer par rôle' })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;
}
