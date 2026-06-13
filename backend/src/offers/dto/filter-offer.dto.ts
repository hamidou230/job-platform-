import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsInt, IsOptional, IsString } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { OfferType, OfferStatus, ExperienceLevel } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';

export class FilterOfferDto extends PaginationDto {
  @ApiPropertyOptional({ enum: OfferType, description: 'Type d’offre' })
  @IsOptional() @IsEnum(OfferType)
  type?: OfferType;

  @ApiPropertyOptional({ description: 'Ville / localisation' })
  @IsOptional() @IsString()
  location?: string;

  @ApiPropertyOptional({ description: 'Télétravail uniquement' })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  isRemote?: boolean;

  @ApiPropertyOptional({ enum: ExperienceLevel })
  @IsOptional() @IsEnum(ExperienceLevel)
  experienceLevel?: ExperienceLevel;

  @ApiPropertyOptional({ enum: OfferStatus, default: 'OPEN' })
  @IsOptional() @IsEnum(OfferStatus)
  status?: OfferStatus;

  @ApiPropertyOptional({ description: 'Salaire minimum souhaité' })
  @IsOptional() @Type(() => Number) @IsInt()
  salaryMin?: number;

  @ApiPropertyOptional({ description: 'Compétences (séparées par des virgules)' })
  @IsOptional() @IsString()
  skills?: string;

  @ApiPropertyOptional({ description: 'Filtrer par entreprise' })
  @IsOptional() @IsString()
  companyId?: string;
}
